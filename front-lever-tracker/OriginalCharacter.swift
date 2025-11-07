import SwiftUI

struct OriginalCharacter: View {
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
                    Circle().fill(Color.black).frame(width: dotSize, height: dotSize).offset(y: -blueLineLength).rotationEffect(blueAngle, anchor: .center).gesture(DragGesture(coordinateSpace: .named("canvas")).onChanged { value in let vectorX = value.location.x - center.x; let vectorY = value.location.y - center.y; blueAngle = Angle(radians: atan2(vectorY, vectorX) + Double.pi / 2)})

                    // Joint dot (Green-Purple)
                    Circle().fill(Color.black).frame(width: dotSize, height: dotSize).offset(y: -greenLineLength).rotationEffect(greenAngle, anchor: .center).offset(y: -blueLineLength).rotationEffect(blueAngle, anchor: .center).gesture(DragGesture(coordinateSpace: .named("canvas")).onChanged { value in let jointX = center.x + blueLineLength * sin(blueAngle.radians); let jointY = center.y - blueLineLength * cos(blueAngle.radians); let vectorX = value.location.x - jointX; let vectorY = value.location.y - jointY; let absoluteAngle = atan2(vectorY, vectorX) + Double.pi / 2; greenAngle = Angle(radians: absoluteAngle) - blueAngle})
                    
                    // Joint dot (Purple-Yellow)
                    Circle()
                        .fill(Color.black)
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
                        .fill(Color.black)
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

struct OriginalCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        OriginalCharacter(
            blueAngle: .constant(Angle(degrees: 235.0)),
            greenAngle: .constant(Angle(degrees: -145.0)),
            purpleAngle: .constant(Angle(degrees: -35.0)),
            yellowAngle: .constant(Angle(degrees: 70.0))
        )
    }
}
