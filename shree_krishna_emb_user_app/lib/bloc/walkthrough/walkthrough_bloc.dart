import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb/models/walkthrough_model.dart';

part 'walkthrough_event.dart';
part 'walkthrough_state.dart';

class WalkthroughBloc extends Bloc<WalkthroughEvent, WalkthroughState> {
  static const int totalPages = 3;

  WalkthroughBloc() : super(const WalkthroughInitial()) {
    on<InitializeWalkthroughEvent>(_onInitialize);
    on<NextPageEvent>(_onNextPage);
    on<PreviousPageEvent>(_onPreviousPage);
    on<GoToPageEvent>(_onGoToPage);
    on<CompleteWalkthroughEvent>(_onCompleteWalkthrough);
  }

  Future<void> _onInitialize(
    InitializeWalkthroughEvent event,
    Emitter<WalkthroughState> emit,
  ) async {
    emit(const WalkthroughLoading());
    try {
      final pages = _getWalkthroughPages();
      emit(
        WalkthroughLoaded(
          pages: pages,
          currentPageIndex: 0,
          isLastPage: false,
          isFirstPage: true,
        ),
      );
    } catch (e) {
      emit(WalkthroughError(e.toString()));
    }
  }

  Future<void> _onNextPage(
    NextPageEvent event,
    Emitter<WalkthroughState> emit,
  ) async {
    if (state is WalkthroughLoaded) {
      final currentState = state as WalkthroughLoaded;
      final nextIndex = currentState.currentPageIndex + 1;

      if (nextIndex < totalPages) {
        emit(
          WalkthroughLoaded(
            pages: currentState.pages,
            currentPageIndex: nextIndex,
            isLastPage: nextIndex == totalPages - 1,
            isFirstPage: false,
          ),
        );
      }
    }
  }

  Future<void> _onPreviousPage(
    PreviousPageEvent event,
    Emitter<WalkthroughState> emit,
  ) async {
    if (state is WalkthroughLoaded) {
      final currentState = state as WalkthroughLoaded;
      final previousIndex = currentState.currentPageIndex - 1;

      if (previousIndex >= 0) {
        emit(
          WalkthroughLoaded(
            pages: currentState.pages,
            currentPageIndex: previousIndex,
            isLastPage: false,
            isFirstPage: previousIndex == 0,
          ),
        );
      }
    }
  }

  Future<void> _onGoToPage(
    GoToPageEvent event,
    Emitter<WalkthroughState> emit,
  ) async {
    if (state is WalkthroughLoaded) {
      final currentState = state as WalkthroughLoaded;
      if (event.pageIndex >= 0 && event.pageIndex < totalPages) {
        emit(
          WalkthroughLoaded(
            pages: currentState.pages,
            currentPageIndex: event.pageIndex,
            isLastPage: event.pageIndex == totalPages - 1,
            isFirstPage: event.pageIndex == 0,
          ),
        );
      }
    }
  }

  Future<void> _onCompleteWalkthrough(
    CompleteWalkthroughEvent event,
    Emitter<WalkthroughState> emit,
  ) async {
    emit(const WalkthroughCompleted());
  }

  List<WalkthroughPage> _getWalkthroughPages() {
    return [
      const WalkthroughPage(
        id: 1,
        title: 'Discover',
        description: 'Explore beautiful embroidery designs from talented artists around the world',
        imagePath: 'assets/images/discover.png',
        backgroundColor: '0xFF6366F1',
        buttonText: 'Next',
      ),
      const WalkthroughPage(
        id: 2,
        title: 'Collaborate',
        description: 'Work together with other designers to create amazing embroidery masterpieces',
        imagePath: 'assets/images/collaborate.png',
        backgroundColor: '0xFF8B5CF6',
        buttonText: 'Next',
      ),
      const WalkthroughPage(
        id: 3,
        title: 'Get Started',
        description: 'Join our community and start creating your own embroidery designs today',
        imagePath: 'assets/images/get_started.png',
        backgroundColor: '0xFFEC4899',
        buttonText: 'Get Started',
      ),
    ];
  }
}
