import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WorkBloc() : super(const WorkInitial()) {
    on<InitializeWorkEvent>(_onInitialize);
    on<FilterVendorWorkEvent>(_onFilterVendorWork);
    on<FilterBuyerOrdersEvent>(_onFilterBuyerOrders);
    on<RefreshWorkDataEvent>(_onRefreshData);
  }

  Future<void> _onInitialize(
    InitializeWorkEvent event,
    Emitter<WorkState> emit,
  ) async {
    emit(const WorkLoading());
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(const WorkError('User not authenticated'));
        return;
      }

      // Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userRole = userDoc.data()?['role'] ?? 'buyer'; // Default to buyer

      // Fetch data based on role
      final vendorProjects = userRole == 'vendor'
          ? await _fetchVendorProjects(userId)
          : <dynamic>[];

      final buyerOrders = userRole == 'buyer'
          ? await _fetchBuyerOrders(userId)
          : <dynamic>[];

      emit(
        WorkLoaded(
          userRole: userRole,
          vendorProjects: vendorProjects,
          buyerOrders: buyerOrders,
          vendorFilter: 'all',
          buyerFilter: 'all',
        ),
      );
    } catch (e) {
      emit(WorkError('Failed to load work data: ${e.toString()}'));
    }
  }

  Future<void> _onFilterVendorWork(
    FilterVendorWorkEvent event,
    Emitter<WorkState> emit,
  ) async {
    if (state is! WorkLoaded) return;
    final currentState = state as WorkLoaded;

    emit(
      WorkLoaded(
        userRole: currentState.userRole,
        vendorProjects: currentState.vendorProjects,
        buyerOrders: currentState.buyerOrders,
        vendorFilter: event.filter,
        buyerFilter: currentState.buyerFilter,
      ),
    );
  }

  Future<void> _onFilterBuyerOrders(
    FilterBuyerOrdersEvent event,
    Emitter<WorkState> emit,
  ) async {
    if (state is! WorkLoaded) return;
    final currentState = state as WorkLoaded;

    emit(
      WorkLoaded(
        userRole: currentState.userRole,
        vendorProjects: currentState.vendorProjects,
        buyerOrders: currentState.buyerOrders,
        vendorFilter: currentState.vendorFilter,
        buyerFilter: event.filter,
      ),
    );
  }

  Future<void> _onRefreshData(
    RefreshWorkDataEvent event,
    Emitter<WorkState> emit,
  ) async {
    add(const InitializeWorkEvent());
  }

  Future<List<dynamic>> _fetchVendorProjects(String userId) async {
    // TODO: Fetch from Firestore based on actual schema
    return [];
  }

  Future<List<dynamic>> _fetchBuyerOrders(String userId) async {
    // TODO: Fetch from Firestore based on actual schema
    return [];
  }
}
