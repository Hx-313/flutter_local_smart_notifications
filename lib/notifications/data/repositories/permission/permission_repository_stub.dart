
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/permission_status.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_permission_repository.dart';

class PermissionRepositoryImpl implements IPermissionRepository {
  PermissionRepositoryImpl({
    required dynamic plugin,
    required dynamic config,
    required dynamic logger,
    required dynamic storage,
  });

  @override
  Future<NotificationResult<PermissionStatus>> check() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('permission'),
    );
  }

  @override
  Future<NotificationResult<PermissionStatus>> request() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('permission'),
    );
  }

  @override
  Future<NotificationResult<void>> openSettings() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('permission'),
    );
  }

  @override
  Future<NotificationResult<bool>> canScheduleExactAlarms() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('permission'),
    );
  }

  @override
  Future<NotificationResult<bool>> requestExactAlarmPermission() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('permission'),
    );
  }
}
