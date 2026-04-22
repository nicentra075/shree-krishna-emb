part of 'walkthrough_bloc.dart';

sealed class WalkthroughState extends Equatable {
  const WalkthroughState();

  @override
  List<Object?> get props => [];
}

class WalkthroughInitial extends WalkthroughState {
  const WalkthroughInitial();
}

class WalkthroughLoading extends WalkthroughState {
  const WalkthroughLoading();
}

class WalkthroughLoaded extends WalkthroughState {
  final List<WalkthroughPage> pages;
  final int currentPageIndex;
  final bool isLastPage;
  final bool isFirstPage;

  const WalkthroughLoaded({
    required this.pages,
    required this.currentPageIndex,
    required this.isLastPage,
    required this.isFirstPage,
  });

  @override
  List<Object?> get props => [pages, currentPageIndex, isLastPage, isFirstPage];
}

class WalkthroughCompleted extends WalkthroughState {
  const WalkthroughCompleted();
}

class WalkthroughError extends WalkthroughState {
  final String message;

  const WalkthroughError(this.message);

  @override
  List<Object?> get props => [message];
}
