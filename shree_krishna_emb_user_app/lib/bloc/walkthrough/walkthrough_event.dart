part of 'walkthrough_bloc.dart';

sealed class WalkthroughEvent extends Equatable {
  const WalkthroughEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWalkthroughEvent extends WalkthroughEvent {
  const InitializeWalkthroughEvent();
}

class NextPageEvent extends WalkthroughEvent {
  const NextPageEvent();
}

class PreviousPageEvent extends WalkthroughEvent {
  const PreviousPageEvent();
}

class GoToPageEvent extends WalkthroughEvent {
  final int pageIndex;

  const GoToPageEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class CompleteWalkthroughEvent extends WalkthroughEvent {
  const CompleteWalkthroughEvent();
}
