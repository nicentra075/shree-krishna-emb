import 'package:equatable/equatable.dart';

abstract class WorkState extends Equatable {
  const WorkState();

  @override
  List<Object?> get props => [];
}

class WorkInitial extends WorkState {
  const WorkInitial();
}

class WorkLoading extends WorkState {
  const WorkLoading();
}

class WorkLoaded extends WorkState {
  final String userRole; // 'vendor' or 'buyer'
  final List<dynamic> vendorProjects; // List<WorkProject> if vendor
  final List<dynamic> buyerOrders; // List<Order> if buyer
  final String vendorFilter; // 'all', 'open', 'inProgress', 'completed'
  final String buyerFilter; // 'all', 'pending', 'delivered'

  const WorkLoaded({
    required this.userRole,
    required this.vendorProjects,
    required this.buyerOrders,
    required this.vendorFilter,
    required this.buyerFilter,
  });

  @override
  List<Object?> get props => [
    userRole,
    vendorProjects,
    buyerOrders,
    vendorFilter,
    buyerFilter,
  ];
}

class WorkError extends WorkState {
  final String message;

  const WorkError(this.message);

  @override
  List<Object?> get props => [message];
}
