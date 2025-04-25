// ai_first_aid_chat.dart

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import the Gemini package

// --- Configuration ---
// IMPORTANT: Replace this with your actual API key.
// Consider using a more secure method like environment variables
// instead of hardcoding the key directly in the source code.
//
// *** API KEY SECURITY & RESTRICTIONS ***
// If you get an error like "requests from this android client are blocked",
// check your API key settings in Google Cloud Console / Google AI Studio.
// Ensure that 'Application restrictions' are either set to 'None' OR
// correctly configured to allow your Android app's package name and SHA-1 fingerprint.
// Hardcoding keys is generally insecure for production apps.
const String _apiKey = "AIzaSyAxgXrWb41vptsMzyG5h3vO85vXUTFg-Yg"; // Use your actual key here

// --- Main Chat Screen Widget ---
class AiFirstAidChatScreen extends StatefulWidget {
  const AiFirstAidChatScreen({Key? key}) : super(key: key);

  @override
  _AiFirstAidChatScreenState createState() => _AiFirstAidChatScreenState();
}

class _AiFirstAidChatScreenState extends State<AiFirstAidChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController(); // For scrolling

  GenerativeModel? _model; // Make the model nullable initially
  bool _isLoading = false; // To show a loading indicator
  bool _apiKeyValid = true; // To track if the API key is valid

  @override
  void initState() {
    super.initState();
    _initializeChat(); // Call the initialization logic
  }

  // --- Initialization Logic ---
  void _initializeChat() {
    // Trim the API key to remove any accidental whitespace
    final trimmedApiKey = _apiKey.trim();

    // Check if the API key is empty.
    if (trimmedApiKey.isEmpty) {
      print("Error: Gemini API Key is empty."); // Log error
      setState(() {
        _apiKeyValid = false; // Mark key as invalid
        _messages.insert(
            0,
            ChatMessage(
              text:
                  "Gemini API Key is empty. Please provide a valid API key.",
              isUser: false,
            ));
      });
      return; // Stop initialization
    }

    // If the key is not empty, try to initialize the model
    try {
      _model = GenerativeModel(
        apiKey: trimmedApiKey, // Use the provided key
        // Consider using 'gemini-1.5-flash-latest' or 'gemini-pro'
        model: 'gemini-2.0-flash',
        // Optional: Add safety settings if needed
        // safetySettings: [
        //   SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        // ],
        // Optional: Add generation config if needed
        // generationConfig: GenerationConfig(
        //   temperature: 0.7,
        // ),
      );
      print("Gemini Model Initialized Successfully."); // Log success
      setState(() {
        _apiKeyValid = true; // Mark key as valid
        // Add an initial greeting message from the bot
        _messages.insert(
            0,
            ChatMessage(
              text: "Hello! How can I help with first aid today?",
              isUser: false,
            ));
      });
    } catch (e) {
      // Catch potential errors during model initialization (e.g., invalid key format, network issues)
      print("Error initializing Gemini Model: $e"); // Log the error
      setState(() {
        _apiKeyValid = false; // Mark key as invalid on error
        _messages.insert(
            0,
            ChatMessage(
              text:
                  "Error initializing the AI model. Please check your API key and configuration. Error: $e",
              isUser: false,
            ));
      });
    }
  }

  // --- Send Message Logic ---
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_apiKeyValid || _model == null) {
      // Don't send if input is empty, key is invalid, or model isn't initialized
      print(
          "Message not sent. Empty input, invalid API key, or model not initialized.");
      if (!_apiKeyValid) {
         _showErrorSnackbar("Cannot send message: API Key is not configured correctly.");
      }
      return;
    }

    _textController.clear(); // Clear the input field

    // Add user message to the list
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true; // Show loading indicator
    });
    _scrollToBottom(); // Scroll down

    // --- Generate Content with Gemini ---
    try {
      // Prepare the content for the API
      final content = [Content.text(text)];

      // Send the request to the Gemini API
      final response = await _model!.generateContent(content);

      // Add bot response to the list
      setState(() {
        _messages.insert(
            0, ChatMessage(text: response.text ?? "...", isUser: false));
        _isLoading = false; // Hide loading indicator
      });
      _scrollToBottom(); // Scroll down
    } catch (e) {
      // Handle API errors (like the restriction error)
      print("Error generating content: $e"); // Log the error
      String errorMessage = "Sorry, I encountered an error communicating with the AI.";
      // Provide a more specific hint for the known restriction error
      if (e.toString().contains('client are blocked')) { // Check if the error message indicates blocking
         errorMessage = "Sorry, requests seem to be blocked. Please check your API key's application restrictions in Google Cloud Console.";
      } else {
         errorMessage = "Sorry, I encountered an error: $e"; // Show generic error otherwise
      }

      setState(() {
        _messages.insert(
            0,
            ChatMessage(
                text: errorMessage, // Display the potentially more specific error
                isUser: false));
        _isLoading = false; // Hide loading indicator
      });
      _scrollToBottom(); // Scroll down
       _showErrorSnackbar(errorMessage); // Show error in snackbar as well
    }
  }

  // --- Helper to scroll to the bottom of the list ---
  void _scrollToBottom() {
    // Use WidgetsBinding to ensure scrolling happens after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent, // Scroll to top (since list is reversed)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

   // --- Helper to show an error message ---
  void _showErrorSnackbar(String message) {
    // Ensure context is still valid before showing SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Define colors (consider moving to a theme file)
    final Color primaryColor = Theme.of(context).primaryColor; // Example: Use theme color

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI First Aid Assistant'),
        backgroundColor: primaryColor, // Use primary color for AppBar
        elevation: 2.0, // Add subtle shadow
      ),
      body: Column(
        children: <Widget>[
          // --- Message List ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign scroll controller
              reverse: true, // Show newest messages at the bottom
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          // --- Loading Indicator ---
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(), // More subtle loading
            ),
          const Divider(height: 1.0),
          // --- Input Area ---
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(primaryColor),
          ),
        ],
      ),
    );
  }

  // --- Text Input Composer Widget ---
  Widget _buildTextComposer(Color primaryColor) {
    return IconTheme(
      data: IconThemeData(color: primaryColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _isLoading || !_apiKeyValid ? null : _sendMessage, // Disable submit while loading or if key invalid
                decoration: InputDecoration(
                  hintText: _apiKeyValid ? "Ask about first aid..." : "API Key not configured",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                ),
                enabled: _apiKeyValid, // Disable input if API key is invalid
              ),
            ),
            const SizedBox(width: 8.0), // Spacing
            // --- Send Button ---
            Container(
              decoration: BoxDecoration(
                 color: (_isLoading || !_apiKeyValid) ? Colors.grey : primaryColor, // Change color when disabled
                 shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading || !_apiKeyValid
                    ? null // Disable button while loading or if key invalid
                    : () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// --- Chat Message Widget ---
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final TextStyle? textStyle; // Optional text style

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define colors (consider moving to a theme file)
    final Color primaryColor = Theme.of(context).primaryColor;
    // *** UPDATED USER BUBBLE COLOR ***
    final Color userBubbleColor = Colors.blue[100]!; // Light blue for user messages
    final Color botBubbleColor = Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // --- Bot Avatar ---
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                child: const Icon(Icons.support_agent, color: Colors.white, size: 18), // AI icon
              ),
            ),
          // --- Message Bubble ---
          Flexible(
            child: Container(
              margin: isUser
                  ? const EdgeInsets.only(left: 40.0) // Ensure space from edge
                  : const EdgeInsets.only(right: 40.0), // Ensure space from edge
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0), // Adjusted padding
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : botBubbleColor, // Use updated user color
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: isUser ? const Radius.circular(16.0) : const Radius.circular(0.0), // Pointy corner for bot
                  bottomRight: isUser ? const Radius.circular(0.0) : const Radius.circular(16.0), // Pointy corner for user
                ),
                boxShadow: [ // Add subtle shadow for depth
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 3.0,
                     offset: const Offset(0, 1),
                   ),
                ],
              ),
              child: SelectableText( // Make text selectable
                text,
                style: textStyle ?? TextStyle(color: Colors.black87, fontSize: 15.0), // Slightly larger font
              ),
            ),
          ),
          // --- User Avatar ---
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue[300], // Slightly darker blue for user avatar
                child: const Icon(Icons.person, color: Colors.white, size: 18), // User icon
              ),
            ),
        ],
      ),
    );
  }
}