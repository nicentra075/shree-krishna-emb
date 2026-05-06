import 'package:equatable/equatable.dart';

abstract class WorkEvent extends Equatable {
  const WorkEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWorkEvent extends WorkEvent {
  const InitializeWorkEvent();
}

class FilterVendorWorkEvent extends WorkEvent {
  final String filter; // 'all', 'open', 'inProgress', 'completed'

  const FilterVendorWorkEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class FilterBuyerOrdersEvent extends WorkEvent {
  final String filter; // 'all', 'pending', 'delivered'

  const FilterBuyerOrdersEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class RefreshWorkDataEvent extends WorkEvent {
  const RefreshWorkDataEvent();
}
