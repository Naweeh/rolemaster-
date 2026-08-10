abstract interface class StateChange {
  Future<void> validate();

  Future<void> apply();

  Future<void> rollback();
}
