import SwiftUI

struct ManipulableLinesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Bindings to allow parent view to control and read angles
    @Binding var blueAngle: Angle
    @Binding var greenAngle: Angle
    @Binding var purpleAngle: Angle
    @Binding var yellowAngle: Angle
    
    init(
        blueAngle: Binding<Angle> = .constant(Angle(degrees: 235.0)),
        greenAngle: Binding<Angle> = .constant(Angle(degrees: -145.0)),
        purpleAngle: Binding<Angle> = .constant(Angle(degrees: -35.0)),
        yellowAngle: Binding<Angle> = .constant(Angle(degrees: 70.0))
    ) {
        self._blueAngle = blueAngle
        self._greenAngle = greenAngle
        self._purpleAngle = purpleAngle
        self._yellowAngle = yellowAngle
    }

    // Define the lengths of the lines and size of the dots
    private let blueLineLength: CGFloat = 80
    private let greenLineLength: CGFloat = 100
    private let purpleLineLength: CGFloat = 60
    private let yellowLineLength: CGFloat = 60
    private let dotSize: CGFloat = 12
    
    // Computed property for dot color based on appearance
    private var dotColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        VStack {
            // --- ANGLE DISPLAY ---
            Text("Joint Angles (in degrees)")
                .font(.headline)
            Text(String(format: "Blue (Absolute): %.2f°", blueAngle.degrees.truncatingRemainder(dividingBy: 360)))
            Text(String(format: "Green (Relative): %.2f°", greenAngle.degrees.truncatingRemainder(dividingBy: 360)))
            Text(String(format: "Purple (Relative): %.2f°", purpleAngle.degrees))
            Text(String(format: "Yellow (Relative): %.2f°", yellowAngle.degrees))
            
            Spacer()

            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                ZStack {
                    // Lines are drawn here... (code unchanged)
                    // Blue Line
                    Line().stroke(Color.blue, lineWidth: 5).frame(height: blueLineLength * 2).rotationEffect(blueAngle, anchor: .center)
                    // Green Line
                    ZStack { Line().stroke(Color.green, lineWidth: 5).frame(height: greenLineLength * 2).rotationEffect(greenAngle, anchor: .center) }.offset(y: -blueLineLength).rotationEffect(blueAngle, anchor: .center)
                    // Purple Line
                    ZStack { Line().stroke(Color.purple, lineWidth: 5).frame(height: purpleLineLength * 2).rotationEffect(purpleAngle, anchor: .center) }.offset(y: -greenLineLength).rotationEffect(greenAngle, anchor: .center).offset(y: -blueLineLength).rotationEffect(blueAngle, anchor: .center)
                    // Yellow Line
                    ZStack { Line().stroke(Color.yellow, lineWidth: 5).frame(height: yellowLineLength * 2).rotationEffect(yellowAngle, anchor: .center) }.offset(y: -purpleLineLength).rotationEffect(purpleAngle, anchor: .center).offset(y: -greenLineLength).rotationEffect(greenAngle, anchor: .center).offset(y: -blueLineLength).rotationEffect(blueAngle, anchor: .center)

                    // --- MANIPULATION DOTS ---
                    
                    // Joint dot (Blue-Green)
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: -blueLineLength)
                        .rotationEffect(blueAngle, anchor: .center)
                        .gesture(
                            DragGesture(coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    // --- Absolute Angle Calculation ---
                                    let vectorX = value.location.x - center.x
                                    let vectorY = value.location.y - center.y
                                    let calculatedAngle = Angle(radians: atan2(vectorY, vectorX) + Double.pi / 2)
                                    
                                    // --- Clamping Logic ---
                                    // Limit blue absolute angle between 190 and 240 degrees
                                    // Normalize to 0-360 range first
                                    var normalizedDegrees = calculatedAngle.degrees.truncatingRemainder(dividingBy: 360)
                                    if normalizedDegrees < 0 {
                                        normalizedDegrees += 360
                                    }
                                    
                                    // Clamp to range
                                    let clampedDegrees = max(190.0, min(normalizedDegrees, 240.0))
                                    
                                    self.blueAngle = Angle(degrees: clampedDegrees)
                                }
                        )

                    // Joint dot (Green-Purple)
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: -greenLineLength)
                        .rotationEffect(greenAngle, anchor: .center)
                        .offset(y: -blueLineLength)
                        .rotationEffect(blueAngle, anchor: .center)
                        .gesture(
                            DragGesture(coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    // --- Relative Angle Calculation ---
                                    let jointX = center.x + blueLineLength * sin(blueAngle.radians)
                                    let jointY = center.y - blueLineLength * cos(blueAngle.radians)
                                    let vectorX = value.location.x - jointX
                                    let vectorY = value.location.y - jointY
                                    let absoluteAngle = atan2(vectorY, vectorX) + Double.pi / 2
                                    let newGreenAngle = Angle(radians: absoluteAngle) - blueAngle
                                    
                                    // --- Clamping Logic ---
                                    // Limit green relative angle between -90 and -175 degrees
                                    let clampedDegrees = max(-175.0, min(newGreenAngle.degrees, -90.0))
                                    
                                    self.greenAngle = Angle(degrees: clampedDegrees)
                                }
                        )
                    
                    // Joint dot (Purple-Yellow)
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: -purpleLineLength)
                        .rotationEffect(purpleAngle, anchor: .center)
                        .offset(y: -greenLineLength)
                        .rotationEffect(greenAngle, anchor: .center)
                        .offset(y: -blueLineLength)
                        .rotationEffect(blueAngle, anchor: .center)
                        .gesture(
                            DragGesture(coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    // --- Relative Angle Calculation ---
                                    let blueGreenJointX = center.x + blueLineLength * sin(blueAngle.radians)
                                    let blueGreenJointY = center.y - blueLineLength * cos(blueAngle.radians)
                                    let greenAbsoluteAngle = blueAngle + greenAngle
                                    let greenPurpleJointX = blueGreenJointX + greenLineLength * sin(greenAbsoluteAngle.radians)
                                    let greenPurpleJointY = blueGreenJointY - greenLineLength * cos(greenAbsoluteAngle.radians)
                                    let vectorX = value.location.x - greenPurpleJointX
                                    let vectorY = value.location.y - greenPurpleJointY
                                    let absoluteAngle = atan2(vectorY, vectorX) + Double.pi / 2
                                    let newPurpleAngle = Angle(radians: absoluteAngle) - greenAbsoluteAngle
                                    
                                    // --- Clamping Logic ---
                                    // This is where the "snap" can happen. If the `newPurpleAngle` value
                                    // jumps from a high positive to a high negative value (or vice-versa)
                                    // due to the atan2 function, it will be forced to the nearest limit.
                                    let clampedDegrees = max(-165.0, min(newPurpleAngle.degrees, 25.0))
                                    
                                    self.purpleAngle = Angle(degrees: clampedDegrees)
                                }
                        )
                        
                    // Yellow end dot
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: -yellowLineLength)
                        .rotationEffect(yellowAngle, anchor: .center)
                        .offset(y: -purpleLineLength)
                        .rotationEffect(purpleAngle, anchor: .center)
                        .offset(y: -greenLineLength)
                        .rotationEffect(greenAngle, anchor: .center)
                        .offset(y: -blueLineLength)
                        .rotationEffect(blueAngle, anchor: .center)
                        .gesture(
                            DragGesture(coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    // --- Relative Angle Calculation ---
                                    let blueGreenJointX = center.x + blueLineLength * sin(blueAngle.radians)
                                    let blueGreenJointY = center.y - blueLineLength * cos(blueAngle.radians)
                                    let greenAbsoluteAngle = blueAngle + greenAngle
                                    let greenPurpleJointX = blueGreenJointX + greenLineLength * sin(greenAbsoluteAngle.radians)
                                    let greenPurpleJointY = blueGreenJointY - greenLineLength * cos(greenAbsoluteAngle.radians)
                                    let purpleAbsoluteAngle = greenAbsoluteAngle + purpleAngle
                                    let purpleYellowJointX = greenPurpleJointX + purpleLineLength * sin(purpleAbsoluteAngle.radians)
                                    let purpleYellowJointY = greenPurpleJointY - purpleLineLength * cos(purpleAbsoluteAngle.radians)
                                    let vectorX = value.location.x - purpleYellowJointX
                                    let vectorY = value.location.y - purpleYellowJointY
                                    let absoluteAngle = atan2(vectorY, vectorX) + Double.pi / 2
                                    let newYellowAngle = Angle(radians: absoluteAngle) - purpleAbsoluteAngle
                                    
                                    // --- Clamping Logic ---
                                    // The same "snap" behavior can occur here if the user drags the dot
                                    // across the 180-degree seam of the atan2 function.
                                    let clampedDegrees = max(0.0, min(newYellowAngle.degrees, 155.0))
                                    self.yellowAngle = Angle(degrees: clampedDegrees)
                                }
                        )
                }
                .position(center)
            }
            .coordinateSpace(name: "canvas")
        }
        .padding()
    }
}

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
        ManipulableLinesView(
            blueAngle: .constant(Angle(degrees: 235.0)),
            greenAngle: .constant(Angle(degrees: -145.0)),
            purpleAngle: .constant(Angle(degrees: -35.0)),
            yellowAngle: .constant(Angle(degrees: 70.0))
        )
    }
}

// MARK: - Static Lines View (Non-interactive)

struct StaticLinesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let blueAngle: Float
    let greenAngle: Float
    let purpleAngle: Float
    let yellowAngle: Float
    let scale: CGFloat
    
    // Define the base lengths of the lines and size of the dots
    private let baseBlueLineLength: CGFloat = 80
    private let baseGreenLineLength: CGFloat = 100
    private let basePurpleLineLength: CGFloat = 60
    private let baseYellowLineLength: CGFloat = 60
    private let baseDotSize: CGFloat = 12
    
    // Computed properties for scaled lengths
    private var blueLineLength: CGFloat { baseBlueLineLength * scale }
    private var greenLineLength: CGFloat { baseGreenLineLength * scale }
    private var purpleLineLength: CGFloat { basePurpleLineLength * scale }
    private var yellowLineLength: CGFloat { baseYellowLineLength * scale }
    private var dotSize: CGFloat { baseDotSize * scale }
    
    // Computed property for dot color based on appearance
    private var dotColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    init(blueAngle: Float, greenAngle: Float, purpleAngle: Float, yellowAngle: Float, scale: CGFloat = 1.0) {
        self.blueAngle = blueAngle
        self.greenAngle = greenAngle
        self.purpleAngle = purpleAngle
        self.yellowAngle = yellowAngle
        self.scale = scale
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            // Convert Float angles to Angle types
            let blue = Angle(degrees: Double(blueAngle))
            let green = Angle(degrees: Double(greenAngle))
            let purple = Angle(degrees: Double(purpleAngle))
            let yellow = Angle(degrees: Double(yellowAngle))
            
            ZStack {
                // Blue Line
                Line()
                    .stroke(Color.blue, lineWidth: 5)
                    .frame(height: blueLineLength * 2)
                    .rotationEffect(blue, anchor: .center)
                
                // Green Line
                ZStack {
                    Line()
                        .stroke(Color.green, lineWidth: 5)
                        .frame(height: greenLineLength * 2)
                        .rotationEffect(green, anchor: .center)
                }
                .offset(y: -blueLineLength)
                .rotationEffect(blue, anchor: .center)
                
                // Purple Line
                ZStack {
                    Line()
                        .stroke(Color.purple, lineWidth: 5)
                        .frame(height: purpleLineLength * 2)
                        .rotationEffect(purple, anchor: .center)
                }
                .offset(y: -greenLineLength)
                .rotationEffect(green, anchor: .center)
                .offset(y: -blueLineLength)
                .rotationEffect(blue, anchor: .center)
                
                // Yellow Line
                ZStack {
                    Line()
                        .stroke(Color.yellow, lineWidth: 5)
                        .frame(height: yellowLineLength * 2)
                        .rotationEffect(yellow, anchor: .center)
                }
                .offset(y: -purpleLineLength)
                .rotationEffect(purple, anchor: .center)
                .offset(y: -greenLineLength)
                .rotationEffect(green, anchor: .center)
                .offset(y: -blueLineLength)
                .rotationEffect(blue, anchor: .center)
                
                // Joint dots (non-interactive)
                // Joint dot (Blue-Green)
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blue, anchor: .center)
                
                // Joint dot (Green-Purple)
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -greenLineLength)
                    .rotationEffect(green, anchor: .center)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blue, anchor: .center)
                
                // Joint dot (Purple-Yellow)
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -purpleLineLength)
                    .rotationEffect(purple, anchor: .center)
                    .offset(y: -greenLineLength)
                    .rotationEffect(green, anchor: .center)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blue, anchor: .center)
                
                // Yellow end dot
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -yellowLineLength)
                    .rotationEffect(yellow, anchor: .center)
                    .offset(y: -purpleLineLength)
                    .rotationEffect(purple, anchor: .center)
                    .offset(y: -greenLineLength)
                    .rotationEffect(green, anchor: .center)
                    .offset(y: -blueLineLength)
                    .rotationEffect(blue, anchor: .center)
            }
            .position(center)
        }
    }
}

struct StaticLinesView_Previews: PreviewProvider {
    static var previews: some View {
        StaticLinesView(
            blueAngle: 235.0,
            greenAngle: -145.0,
            purpleAngle: -35.0,
            yellowAngle: 70.0
        )
        .frame(width: 200, height: 200)
    }
}
