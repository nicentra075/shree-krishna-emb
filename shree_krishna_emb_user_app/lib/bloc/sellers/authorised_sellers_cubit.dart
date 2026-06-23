import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/domain/entities/seller.dart';
import 'package:shree_krishna_emb/domain/repositories/seller_repository.dart';

abstract class AuthorisedSellersState extends Equatable {
  const AuthorisedSellersState();

  @override
  List<Object?> get props => [];
}

class AuthorisedSellersInitial extends AuthorisedSellersState {
  const AuthorisedSellersInitial();
}

class AuthorisedSellersLoading extends AuthorisedSellersState {
  const AuthorisedSellersLoading();
}

class AuthorisedSellersLoaded extends AuthorisedSellersState {
  final List<SellerEntity> sellers;
  const AuthorisedSellersLoaded(this.sellers);

  @override
  List<Object?> get props => [sellers];
}

class AuthorisedSellersError extends AuthorisedSellersState {
  final String message;
  const AuthorisedSellersError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthorisedSellersCubit extends Cubit<AuthorisedSellersState> {
  final SellerRepository repository;

  AuthorisedSellersCubit({required this.repository})
      : super(const AuthorisedSellersInitial());

  Future<void> load() async {
    emit(const AuthorisedSellersLoading());
    final result = await repository.getAuthorisedSellers();
    result.fold(
      (failure) => emit(AuthorisedSellersError(failure.message)),
      (sellers) => emit(AuthorisedSellersLoaded(sellers)),
    );
  }
}
