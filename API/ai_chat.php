<?php
/**
 * AI Chat API (Gemini Integration)
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// --- CONFIGURATION ---AIzaSyCnrd8MyUqbAa5ev4tcEgMfQx6AZYfr_QM
// Get your API key from https://aistudio.google.com/app/apikey
$GEMINI_API_KEY = " your API key here";
// ---------------------

// Get input data
$input = json_decode(file_get_contents("php://input"), true);
$message = $input['message'] ?? '';

if (empty($message)) {
    echo json_encode([
        'success' => false,
        'message' => 'Message is required'
    ]);
    exit;
}

if ($GEMINI_API_KEY === "YOUR_GEMINI_API_KEY_HERE") {
    // Return a helpful error if the key isn't set yet
    echo json_encode([
        'success' => true,
        'ai_response' => "I am currently in 'Demo Mode'. Please add a real Gemini API Key to sami/ai_chat.php to enable my full intelligence! You can get a free key at https://aistudio.google.com/"
    ]);
    exit;
}

try {
    // This is the most standard model name that works with the v1 endpoint
    $url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=" . $GEMINI_API_KEY;

    $data = [
        "contents" => [
            [
                "parts" => [
                    ["text" => "You are ASTU-Q AI, a helpful study assistant for students at Adama Science and Technology University. Answer the following question helpfully and concisely: " . $message]
                ]
            ]
        ]
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // For local dev if needed

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $result = json_decode($response, true);
        $aiText = $result['candidates'][0]['content']['parts'][0]['text'] ?? "I'm sorry, I couldn't process that.";
        
        echo json_encode([
            'success' => true,
            'ai_response' => $aiText
        ]);
    } else {
        // Log the actual error from Gemini for debugging
        $errorDetails = json_decode($response, true);
        $errorMessage = $errorDetails['error']['message'] ?? 'Unknown AI error';
        
        echo json_encode([
            'success' => false,
            'message' => 'AI Service Error: ' . $errorMessage,
            'debug_raw' => $response // Temporary for debugging
        ]);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>  
