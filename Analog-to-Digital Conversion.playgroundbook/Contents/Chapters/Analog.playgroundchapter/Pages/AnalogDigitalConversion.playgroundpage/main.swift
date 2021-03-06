/*:
Finally, we are ready to explore how analog signals are converted to digital ones. In the Live View, you see the diagram of a *successive approximation analog-to-digital converter*.

This circuit works by comparing the input voltage to a voltage generated by a digital-to-analog (“D/A”) converter. A logic implements *binary search* to quickly find the closest matching voltage the D/A converter is able to generate. Since the closest matching voltage is also the best representable approximation of the input signal, the fixed-point number used to generate this voltage is the result of the analog-to-digital conversion.

This logic is implemented in the code down below. Isn’t it wonderful that algorithms of the world of computer science also have applications in the electrical domain?

- Experiment:
Vary the parameters below and see how the obtained digital signal changes. **Adjust the parameters in a way that the main voltage peak at approximately 0.25 seconds can be identified in the acquired digital signal.**
*/
//#-code-completion(everything, hide)
//#-code-completion(literal, show, integer)
//#-hidden-code
import Book
import Foundation
import PlaygroundSupport
import Darwin

var numberOfBits: Int = 0
var maximumVoltage: Double = 0.0
var timeBetweenConversions: TimeInterval = 0.5

func setNumberOfBits(_ value: Int) {
	guard (2...UInt64.bitWidth).contains(value) else {
		fatalError("This example requires 2 bits at least and 64 bits at most.")
	}
	numberOfBits = value
}

func setMaximumVoltage(_ value: Double) {
	guard value > 0.0 else {
		fatalError("This example only supports maximum voltages that are larger than zero.")
	}
	maximumVoltage = value
}

func setTimeBetweenConversions(_ value: TimeInterval) {
	guard value > 0.0 else {
		fatalError("The time between conversions must be larger than zero.")
	}
	timeBetweenConversions = value
}
//#-end-hidden-code
setNumberOfBits(/*#-editable-code*/8/*#-end-editable-code*/)
setMaximumVoltage(/*#-editable-code*/0.02/*#-end-editable-code*/)
setTimeBetweenConversions(/*#-editable-code*/0.07/*#-end-editable-code*/)
/*:
- Callout(Tip):
Try the different execution modes by tapping on the stopwatch button next to the “Run My Code” button. For example, choose “Step Through My Code” to see how the algorithm implemented in the logic works line-by-line, or choose “Run Fastest” to quickly obtain the conversion result.
*/
//#-hidden-code

let remoteView = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
var resistorLadder = R2RResistorLadder(numberOfBits: numberOfBits, referenceVoltage: maximumVoltage)
var currentTime: TimeInterval = 0.0

var delay: TimeInterval {
	switch PlaygroundPage.current.executionMode {
	case .run:
		return 0.2
	case .runFaster:
		return 0.1
	default:
		return 0.0
	}
}

func setBit(at index: Int) {
	resistorLadder.setBit(at: index)

	remoteView.send(.dictionary([
		"SetBit": .integer(index),
		"ShowOutputVoltage": .dictionary([
			"Time": .floatingPoint(currentTime),
			"Voltage": .floatingPoint(resistorLadder.outputVoltage)
		])
	]))

	Thread.sleep(forTimeInterval: delay)
}

func clearBit(at index: Int) {
	resistorLadder.clearBit(at: index)

	remoteView.send(.dictionary([
		"ClearBit": .integer(index),
		"ShowOutputVoltage": .dictionary([
			"Time": .floatingPoint(currentTime),
			"Voltage": .floatingPoint(resistorLadder.outputVoltage)
		])
	]))

	Thread.sleep(forTimeInterval: delay)
}

func clearAllBits() {
	resistorLadder.clearAllBits()

	if currentTime >= timeBetweenConversions {
		remoteView.send(.dictionary([
			"ClearAllBits": .boolean(true),
			"ShowOutputVoltage": .dictionary([
				"Time": .floatingPoint(currentTime - timeBetweenConversions),
				"Voltage": .floatingPoint(resistorLadder.outputVoltage)
			])
		]))

		Thread.sleep(forTimeInterval: max(PlaygroundPage.current.executionMode == .runFastest ? 0.001 : 0.1, delay))

		remoteView.send(.dictionary([
			"ClearAllBits": .boolean(true),
			"ShowOutputVoltage": .dictionary([
				"Time": .floatingPoint(currentTime),
				"Voltage": .floatingPoint(resistorLadder.outputVoltage)
			])
		]))
	} else {
		remoteView.send(.dictionary([
			"ClearAllBits": .boolean(true),
			"ShowOutputVoltage": .dictionary([
				"Time": .floatingPoint(currentTime),
				"Voltage": .floatingPoint(resistorLadder.outputVoltage)
			])
		]))

		Thread.sleep(forTimeInterval: delay)
	}
}

func getOutputValue() -> Double {
	resistorLadder.outputVoltage
}

func getNextInputValue() -> OpaqueSignalValue? {
	// Validate user-configurable parameters here since fatalError() seems to show a error message to the user only when called inside a function that is called in non-hidden code
	guard maximumVoltage > 0.0 else {
		fatalError("The maximum voltage must be larger than zero.")
	}
	guard timeBetweenConversions > 0.0 else {
		fatalError("The sample rate must be larger than zero.")
	}

	if currentTime <= 0.7 {
		return getInputSignalValue(at: currentTime)
	} else {
		return nil
	}
}

func saveResult(_ value: Double) {
	Thread.sleep(forTimeInterval: delay)

	remoteView.send(.dictionary([
		"SaveSample": .dictionary([
			"Time": .floatingPoint(currentTime),
			"Voltage": .floatingPoint(resistorLadder.outputVoltage)
		])
	]))
}

func incrementTime() {
	currentTime += timeBetweenConversions
}

remoteView.send(.dictionary([
	"SetDacResolution": .integer(numberOfBits),
	"SetMaximumVoltage": .floatingPoint(maximumVoltage),
	"ClearSamples": .boolean(true)
]))

//#-end-hidden-code
while let inputValue = getNextInputValue() {
    clearAllBits()

	for index in (0..<numberOfBits).reversed() {
        setBit(at: index)

		// Note: In a real-world converter, the comparison of the two voltages is performed in the comparator (which is shown as a triangle with a plus and a minus symbol in the circuit diagram). The logic would only receive a binary input from the comparator containing the comparison result.
        if inputValue < getOutputValue() {
            clearBit(at: index)
        }
	}

	saveResult(getOutputValue())
	//#-hidden-code

	incrementTime()
	//#-end-hidden-code
}
//#-hidden-code

clearAllBits()

remoteView.send(.dictionary([
	"CheckForAssessmentFailure": .boolean(true)
]))

//#-end-hidden-code
