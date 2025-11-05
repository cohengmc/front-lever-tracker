import SwiftUI

struct ManipulableLinesView: View {
    // State variables for the angles of each line
    @State private var redAngle = Angle.zero
    @State private var blueAngle = Angle.zero
    @State private var greenAngle = Angle.zero // Angle of the green line relative to the blue line

    // Define the ACTUAL lengths of the lines and size of the dots
    private let redLineLength: CGFloat = 120
    private let blueLineLength: CGFloat = 100
    private let greenLineLength: CGFloat = 80
    private let dotSize: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Red Line
                // The frame height is now 2x the length because our Line shape
                // draws from the center to the edge (a radius).
                Line()
                    .stroke(Color.red, lineWidth: 5)
                    .frame(height: redLineLength * 2)
                    .rotationEffect(redAngle, anchor: .center)

                // Blue Line
                Line()
                    .stroke(Color.blue, lineWidth: 5)
                    .frame(height: blueLineLength * 2)
                    .rotationEffect(blueAngle, anchor: .center)

                // Green Line - positioned relative to the blue line
                ZStack {
                    Line()
                        .stroke(Color.green, lineWidth: 5)
                        .frame(height: greenLineLength * 2)
                        .rotationEffect(greenAngle, anchor: .center)
                }
                // The group is offset by the blue line's length to place its
                // origin at the tip of the blue line.
                .offset(y: -blueLineLength)
                .rotationEffect(blueAngle, anchor: .center)


                // --- MANIPULATION DOTS ---

                // Red dot - offset by the actual line length
                Circle()
                    .fill(Color.black)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -redLineLength)
                    .rotationEffect(redAngle, anchor: .center)
                    .gesture(
                        DragGesture(coordinateSpace: .named("canvas"))
                            .onChanged { value in
                                let vectorX = value.location.x - center.x
                                let vectorY = value.location.y - center.y
                                redAngle = Angle(radians: atan2(vectorY, vectorX) + Double.pi / 2)
                            }
                    )
                
                // Joint dot (Blue-Green)
                Circle()
                    .fill(Color.black)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blueAngle, anchor: .center)
                    .gesture(
                        DragGesture(coordinateSpace: .named("canvas"))
                            .onChanged { value in
                                let vectorX = value.location.x - center.x
                                let vectorY = value.location.y - center.y
                                blueAngle = Angle(radians: atan2(vectorY, vectorX) + Double.pi / 2)
                            }
                    )

                // Green end dot
                Circle()
                    .fill(Color.black)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -greenLineLength)
                    .rotationEffect(greenAngle, anchor: .center)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blueAngle, anchor: .center)
                    .gesture(
                        DragGesture(coordinateSpace: .named("canvas"))
                            .onChanged { value in
                                // Calculate the absolute canvas position of the joint
                                let jointX = center.x + blueLineLength * sin(blueAngle.radians)
                                let jointY = center.y - blueLineLength * cos(blueAngle.radians)

                                // Create a vector from the joint to the drag location
                                let vectorX = value.location.x - jointX
                                let vectorY = value.location.y - jointY

                                // Calculate the absolute angle of the green line based on the vector
                                let absoluteAngle = atan2(vectorY, vectorX) + Double.pi / 2

                                // The green angle is relative to the blue angle, so we subtract it
                                greenAngle = Angle(radians: absoluteAngle) - blueAngle
                            }
                    )
            }
            .position(center)
        }
        .coordinateSpace(name: "canvas")
        .frame(width: 500, height: 500) // Increased frame size to accommodate lines
    }
}

// This shape now draws a line from its center upwards to its top edge.
// The length of the line is exactly half the height of the frame it's in.
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}


struct ManipulableLinesView_Previews: PreviewProvider {
    static var previews: some View {
        ManipulableLinesView()
    }
}
