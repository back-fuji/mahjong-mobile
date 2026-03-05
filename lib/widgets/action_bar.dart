import 'package:flutter/material.dart';

/// Action bar: tsumo_agari, ron, riichi, pon, chi, kan, skip_call, kyuushu, next_round.
/// Visibility driven by availableActions and phase.
class ActionBarWidget extends StatelessWidget {
  const ActionBarWidget({
    super.key,
    required this.availableActions,
    required this.onAction,
    this.chiOptionCount = 0,
    this.onChiOptionSelect,
    this.kanTilesCount = 0,
  });

  final List<String> availableActions;
  final void Function(String action, [Map<String, dynamic>? params]) onAction;
  final int chiOptionCount;
  final void Function(List<int> tiles)? onChiOptionSelect;
  final int kanTilesCount;

  bool _has(String action) => availableActions.contains(action);

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (_has('tsumo_agari')) {
      actions.add(_btn('ツモ和了', () => onAction('tsumo_agari')));
    }
    if (_has('ron')) {
      actions.add(_btn('ロン', () => onAction('ron')));
    }
    if (_has('riichi')) {
      actions.add(_btn('リーチ', () => onAction('riichi')));
    }
    if (_has('pon')) {
      actions.add(_btn('ポン', () => onAction('pon')));
    }
    if (_has('chi')) {
      actions.add(_btn('チー', () => onAction('chi')));
    }
    if (_has('kan')) {
      actions.add(_btn('カン', () => onAction('kan')));
    }
    if (_has('skip_call')) {
      actions.add(_btn('スキップ', () => onAction('skip_call')));
    }
    if (_has('kyuushu')) {
      actions.add(_btn('九種九牌', () => onAction('kyuushu')));
    }
    if (_has('next_round')) {
      actions.add(_btn('次局', () => onAction('next_round')));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: actions,
    );
  }

  Widget _btn(String label, VoidCallback onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
