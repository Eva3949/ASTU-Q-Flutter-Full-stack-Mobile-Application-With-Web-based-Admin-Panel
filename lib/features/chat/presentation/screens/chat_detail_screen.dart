import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/chat_detail_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Chat Detail Screen
/// Displays individual chat conversation with messages and input
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({Key? key}) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late FocusNode _messageFocusNode;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();

    // Stop polling when leaving the screen
    final provider = Provider.of<ChatDetailProvider>(context, listen: false);
    provider.reset();

    super.dispose();
  }

  void _initializeControllers() {
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _messageFocusNode = FocusNode();

    // Listen to scroll events for auto-loading older messages
    _scrollController.addListener(_onScroll);

    // Listen to message controller changes
    _messageController.addListener(_onMessageChanged);
  }

  void _initializeChat() {
    // Get chat arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      final provider = Provider.of<ChatDetailProvider>(context, listen: false);

      provider.initializeChat(
        conversationId: args['conversationId'],
        userName: args['userName'],
        userAvatar: args['userAvatar'],
        isGroupChat: args['isGroupChat'] ?? false,
        otherUser: args['otherUser'],
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) {
      // Load more messages when near top
      final provider = Provider.of<ChatDetailProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreMessages();
      }
    }
  }

  void _onMessageChanged() {
    final provider = Provider.of<ChatDetailProvider>(context, listen: false);
    provider.updateMessageInput(_messageController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: SafeArea(
          child: Consumer<ChatDetailProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.messages.isEmpty) {
                return const Center(
                  child: LoadingWidget(message: 'Loading messages...'),
                );
              }

              if (provider.errorMessage != null && provider.messages.isEmpty) {
                return _buildErrorState(provider);
              }

              return _buildContent(provider);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Consumer<ChatDetailProvider>(
        builder: (context, provider, child) {
          return AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: AppTheme.systemUiOverlayStyle,
            title: Row(
              children: [
                // User Avatar
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: provider.userAvatar != null
                        ? Image.network(
                            provider.userAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                provider.isGroupChat
                                    ? Icons.group
                                    : Icons.person,
                                size: 20.sp,
                                color: AppColors.primaryColor,
                              );
                            },
                          )
                        : Icon(
                            provider.isGroupChat ? Icons.group : Icons.person,
                            size: 20.sp,
                            color: AppColors.primaryColor,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.userName ?? 'Chat',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        provider.isGroupChat ? 'Group Chat' : 'Online',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
            actions: [
              IconButton(
                onPressed: _handleVoiceCall,
                icon: Icon(Icons.phone, color: AppColors.textSecondary),
              ),
              IconButton(
                onPressed: _handleVideoCall,
                icon: Icon(Icons.videocam, color: AppColors.textSecondary),
              ),
              IconButton(
                onPressed: _handleMoreOptions,
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ChatDetailProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.errorColor),
            SizedBox(height: 24.h),
            Text(
              'No Internet connection',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'Try Again',
              onPressed: () {
                provider.refreshMessages();
              },
              prefixIcon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ChatDetailProvider provider) {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.refreshMessages();
            },
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Show newest messages at bottom
              padding: EdgeInsets.all(16.w),
              itemCount:
                  provider.messageCount + (provider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.messageCount && provider.isLoadingMore) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Center(child: LoadingWidget(size: 24)),
                  );
                }

                // Reverse index for reverse list
                final reversedIndex = provider.messageCount - 1 - index;
                final message = provider.messages[reversedIndex];
                final previousMessage =
                    reversedIndex < provider.messageCount - 1
                    ? provider.messages[reversedIndex + 1]
                    : null;
                final nextMessage = reversedIndex > 0
                    ? provider.messages[reversedIndex - 1]
                    : null;

                return Column(
                  children: [
                    // Date separator
                    if (previousMessage == null ||
                        !_isSameDay(
                          message.createdAt,
                          previousMessage.createdAt,
                        ))
                      _buildDateSeparator(message.createdAt),

                    // Message bubble
                    MessageBubble(
                      message: message,
                      showAvatar: provider.shouldShowAvatar(
                        message,
                        nextMessage,
                      ),
                      showTimestamp: provider.shouldShowTimestamp(
                        message,
                        previousMessage,
                      ),
                      onImageTap: (imageUrl) => _handleImageTap(imageUrl),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Typing Indicator
        if (provider.isTyping || provider.typingUsers.isNotEmpty)
          _buildTypingIndicator(provider),

        // Message Input
        _buildMessageInput(provider),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              _formatDateHeader(date),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ChatDetailProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Typing dots animation
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: Stack(
              children: [
                Positioned(left: 0, top: 8.h, child: _buildTypingDot(0)),
                Positioned(left: 8.w, top: 8.h, child: _buildTypingDot(1)),
                Positioned(left: 16.w, top: 8.h, child: _buildTypingDot(2)),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            provider.getTypingIndicatorText(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + 0.5 * ((value + index * 0.3) % 1.0),
          child: Container(
            width: 4.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ChatDetailProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Attach Button
          IconButton(
            onPressed: () => _handleAttachment(),
            icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
          ),

          // Camera Button
          IconButton(
            onPressed: () => _handleCamera(),
            icon: Icon(Icons.camera_alt, color: AppColors.textSecondary),
          ),

          // Message Input
          Expanded(
            child: CustomTextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              hintText: 'Type a message...',
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _handleSendMessage(),
              onChanged: (value) {
                // Handled by listener
              },
            ),
          ),

          SizedBox(width: 8.w),

          // Send Button
          CustomButton(
            text: '',
            onPressed:
                provider.messageInput.trim().isNotEmpty &&
                    !provider.isSendingMessage
                ? _handleSendMessage
                : null,
            isLoading: provider.isSendingMessage,
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
            prefixIcon: Icons.send,
            width: 48.w,
            height: 48.h,
          ),
        ],
      ),
    );
  }

  // Event Handlers
  void _handleSendMessage() async {
    final provider = Provider.of<ChatDetailProvider>(context, listen: false);

    if (await provider.sendMessage()) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _handleAttachment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAttachmentSheet(),
    );
  }

  Widget _buildAttachmentSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'Share',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Options
          Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.primaryColor,
                ),
                title: Text('Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handlePickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: AppColors.primaryColor),
                title: Text('Video'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video sharing coming soon!'),
                      backgroundColor: AppColors.infoColor,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: AppColors.primaryColor,
                ),
                title: Text('Document'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document sharing coming soon!'),
                      backgroundColor: AppColors.infoColor,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: AppColors.primaryColor),
                title: Text('Location'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location sharing coming soon!'),
                      backgroundColor: AppColors.infoColor,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _handleCamera() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Take Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('Record Video'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      if (source == ImageSource.camera) {
        _handlePickImage(source: source);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video recording coming soon!'),
            backgroundColor: AppColors.infoColor,
          ),
        );
      }
    }
  }

  void _handlePickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final provider = Provider.of<ChatDetailProvider>(
          context,
          listen: false,
        );
        await provider.sendImageMessage(image.path);
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _handleImageTap(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }

  void _handleVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice call coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video call coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _handleMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoreOptionsSheet(),
    );
  }

  Widget _buildMoreOptionsSheet() {
    return Consumer<ChatDetailProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'More Options',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Options
              Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.search, color: AppColors.primaryColor),
                    title: Text('Search in Conversation'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Search coming soon!'),
                          backgroundColor: AppColors.infoColor,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.notifications_off,
                      color: AppColors.primaryColor,
                    ),
                    title: Text('Mute Notifications'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mute notifications coming soon!'),
                          backgroundColor: AppColors.infoColor,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: AppColors.infoColor,
                    ),
                    title: Text('View Info'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('View info coming soon!'),
                          backgroundColor: AppColors.infoColor,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.errorColor,
                    ),
                    title: Text('Clear Chat'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleClearChat();
                    },
                  ),
                ],
              ),

              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _handleClearChat() {
    ModernDialog.showConfirmation(
      context: context,
      title: 'Clear Chat',
      message:
          'Are you sure you want to clear all messages in this conversation? This action cannot be undone.',
      primaryText: 'Clear',
      secondaryText: 'Cancel',
      icon: Icons.delete_sweep,
      iconColor: const Color(0xFFF44336),
    ).then((confirmed) {
      if (confirmed == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear chat coming soon!'),
            backgroundColor: AppColors.infoColor,
          ),
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Message Bubble Widget
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final void Function(String)? onImageTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.showAvatar,
    required this.showTimestamp,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFromCurrentUser = message.isFromCurrentUser;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar) ...[
            // Avatar
            Container(
              width: 32.w,
              height: 32.h,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 16.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ],

          // Message Content
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? AppColors.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16.r).copyWith(
                      bottomLeft: isFromCurrentUser
                          ? Radius.circular(16.r)
                          : Radius.circular(4.r),
                      bottomRight: isFromCurrentUser
                          ? Radius.circular(4.r)
                          : Radius.circular(16.r),
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    border: !isFromCurrentUser
                        ? Border.all(color: Colors.grey[200]!)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(),
                ),

                // Timestamp
                if (showTimestamp)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4.h,
                      left: isFromCurrentUser ? 0 : 40.w,
                      right: isFromCurrentUser ? 40.w : 0,
                    ),
                    child: Text(
                      _formatTimestamp(message.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isFromCurrentUser && showAvatar) ...[
            // Spacer for alignment
            SizedBox(width: 40.w),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case 'text':
        return Text(
          message.content,
          style: AppTextStyles.bodyText2.copyWith(
            color: message.isFromCurrentUser
                ? Colors.white
                : AppColors.textPrimary,
          ),
        );
      case 'image':
        return GestureDetector(
          onTap: () => onImageTap?.call(message.content),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              Container(
                width: 200.w,
                height: 150.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    message.content,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 32.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (message.metadata?['caption'] != null) ...[
                SizedBox(height: 4.h),
                Text(
                  message.metadata!['caption'],
                  style: AppTextStyles.caption.copyWith(
                    color: message.isFromCurrentUser
                        ? Colors.white70
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      case 'file':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message.isFromCurrentUser
                  ? Colors.white70
                  : AppColors.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                message.content,
                style: AppTextStyles.bodyText2.copyWith(
                  color: message.isFromCurrentUser
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: message.isFromCurrentUser
                  ? Colors.white70
                  : AppColors.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Voice message',
              style: AppTextStyles.bodyText2.copyWith(
                color: message.isFromCurrentUser
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ],
        );
      case 'location':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: message.isFromCurrentUser
                  ? Colors.white70
                  : AppColors.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Location',
              style: AppTextStyles.bodyText2.copyWith(
                color: message.isFromCurrentUser
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: AppTextStyles.bodyText2.copyWith(
            color: message.isFromCurrentUser
                ? Colors.white
                : AppColors.textPrimary,
          ),
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (timestamp.year == now.year) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Image Viewer Screen
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64.sp,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
