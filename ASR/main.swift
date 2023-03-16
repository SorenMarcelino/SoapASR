//
//  main.swift
//  ASR
//
//  Created by Soren Marcelino on 07/03/2023.
//

//MARK: ASR fonctionne en SOAP
import Foundation
import Speech
import Swifter
import Socket

let server = HttpServer()

class XMLParserDelegateCustom: NSObject, XMLParserDelegate {
    var foundAudioData = false
        var audioData: Data?
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if foundAudioData {
                audioData = Data(base64Encoded: string, options: .ignoreUnknownCharacters)
                foundAudioData = false
                print("Audio data decoded successfully.")
            }
        }
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "audio" {
                foundAudioData = true
            }
        }
}

func transcribeAudio(request: HttpRequest) -> HttpResponse {
    let data = Data(request.body)
    let parser = XMLParser(data: data)
    let delegate = XMLParserDelegateCustom()
    parser.delegate = delegate
    parser.parse()
        
    // Decode the base64-encoded audio data
    guard let audioData = delegate.audioData, let audioURL = writeAudioDataToFile(data: audioData) else {
        return .internalServerError
    }

    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    let request = SFSpeechURLRecognitionRequest(url: audioURL)

    let semaphore = DispatchSemaphore(value: 0)
    var transcription: String?
    
    recognizer?.recognitionTask(with: request) { result, error in
        var isFinal = false
        
        if let result = result {
            // Update the text view with the results.
            isFinal = result.isFinal
            transcription = result.bestTranscription.formattedString
            print("Not final Text : \(result.bestTranscription.formattedString)") // Print the results during listening
        }
        
        if error != nil || isFinal {
            print("Transcription Finale: \(transcription ?? "")")
            semaphore.signal()
        }
    }
    
    _ = semaphore.wait(timeout: .distantFuture)

    guard let transcribedText = transcription else {
        return .internalServerError
    }

    let soapResponse = """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
            <transcription>\(transcribedText)</transcription>
        </soap:Body>
    </soap:Envelope>
    """

    return HttpResponse.raw(200, "OK", ["Content-Type": "application/xml"], { writer in
        guard let data = soapResponse.data(using: .utf8) else {
            print("ERROR 500")
            return
        }
        try writer.write(data)
    })
}

func helloWorld(request: HttpRequest) -> HttpResponse {
    let soapResponse = """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
            <transcription>Bonjour le Monde</transcription>
        </soap:Body>
    </soap:Envelope>
    """
    return HttpResponse.raw(200, "OK", ["Content-Type": "application/xml"], { writer in
        guard let data = soapResponse.data(using: .utf8) else {
            print("ERROR 500")
            return
        }
        try writer.write(data)
    })}

server.POST["/transcribe"] = { request in
    return transcribeAudio(request: request)
}

server.GET["/"] = { request in
    return helloWorld(request: request)
}

func writeAudioDataToFile(data: Data) -> URL? {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = directory.appendingPathComponent("audioData.mp3")

    do {
        try data.write(to: fileURL)
        return fileURL
    } catch {
        print("Error writing audio data to file: \(error)")
        return nil
    }
}

do {
    try server.start(45876, forceIPv4: true)
    
    print("Server is running on http://192.168.1.154:45876/")
    RunLoop.main.run()
} catch {
    print("Error starting server: \(error)")
}




//MARK: ASR fonctionne en HTTP Server
/*import Foundation
import Speech
import Swifter

let server = HttpServer()

func transcribeAudio(request: HttpRequest) -> HttpResponse {
    let audioURL = URL(fileURLWithPath: "/Users/soren/Desktop/ASR/ASR/MacronASRTestPart.mp3")
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    var transcription: String?

    let semaphore = DispatchSemaphore(value: 0)
    recognizer?.recognitionTask(with: request) { result, error in
        // Handle any errors that occurred during transcription
        guard error == nil else {
            print("Error: \(error!)")
            return
        }

        // Extract the transcription from the result
        let transcription = result?.bestTranscription.formattedString

        // Print the transcription to the console
        print("Transcription: \(transcription ?? "")")
    }
    
    return .ok(.html(transcription ?? ""))
}

server.POST["/transcribe"] = { request in
    return transcribeAudio(request: request)
}

do {
    try server.start(45876)
    print("Server is running on http://localhost:45876/")
    RunLoop.main.run()
} catch {
    print("Error starting server: \(error)")
}*/




//MARK: ASR fonctionne en standalone
/*import Foundation
import Speech

// Replace "path/to/audio/file" with the actual path to your audio file
let audioURL = URL(fileURLWithPath: "MacronASRTestPart.mp3")

// Set up a speech recognizer and configure it for transcription
let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
let request = SFSpeechURLRecognitionRequest(url: audioURL)

// Perform the transcription asynchronously
recognizer?.recognitionTask(with: request) { result, error in
    // Handle any errors that occurred during transcription
    guard error == nil else {
        print("Error: \(error!)")
        return
    }

    // Extract the transcription from the result
    let transcription = result?.bestTranscription.formattedString

    // Print the transcription to the console
    print("Transcription: \(transcription ?? "")")
}

// Wait for the transcription to complete
RunLoop.main.run()*/
