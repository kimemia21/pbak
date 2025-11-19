import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/member_service.dart';

// Service provider
final memberServiceProvider = Provider((ref) => MemberService());

// All members provider
final membersProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.read(memberServiceProvider);
  return await service.getAllMembers();
});

// Member by ID provider
final memberByIdProvider = FutureProvider.family<UserModel?, int>((ref, memberId) async {
  final service = ref.read(memberServiceProvider);
  return await service.getMemberById(memberId);
});

// Member stats provider
final memberStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(memberServiceProvider);
  return await service.getMemberStats();
});

// Member state notifier for managing member-related operations
class MemberNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final MemberService _memberService;

  MemberNotifier(this._memberService) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _memberService.getAllMembers();
      state = AsyncValue.data(members);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateMemberParams(int memberId, Map<String, dynamic> params) async {
    try {
      final success = await _memberService.updateMemberParams(
        memberId: memberId,
        params: params,
      );
      
      if (success) {
        // Reload members after update
        await loadMembers();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    loadMembers();
  }
}

// Member state provider
final memberNotifierProvider = StateNotifierProvider<MemberNotifier, AsyncValue<List<UserModel>>>((ref) {
  return MemberNotifier(ref.read(memberServiceProvider));
});
