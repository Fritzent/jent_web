enum EmailStatus { idle, sending, sent, error }

class MailState {
  final bool isShowWindow;
  final bool isMinimizedWindow;
  final bool isExpandedWindow;
  final EmailStatus emailStatus;

  const MailState({
    this.isShowWindow = false,
    this.isMinimizedWindow = false,
    this.isExpandedWindow = false,
    this.emailStatus = EmailStatus.idle,
  });

  MailState copyWith({
    bool? isShowWindow,
    bool? isMinimizedWindow,
    bool? isExpandedWindow,
    EmailStatus? emailStatus,
  }) {
    return MailState(
      isShowWindow: isShowWindow ?? this.isShowWindow,
      isMinimizedWindow: isMinimizedWindow ?? this.isMinimizedWindow,
      isExpandedWindow: isExpandedWindow ?? this.isExpandedWindow,
      emailStatus: emailStatus ?? this.emailStatus,
    );
  }
}
