"""Print the robot's servo and diagnostics state for `ta fix` (one shot).

Run by ``ta`` with the student's own sourced ROS environment while a robot
launch is up. It listens for a few seconds and prints:

* The board (RCB-4mini): whether the servo switch reports it answering
  (``/diagnostics`` status ``actuo_bus_servicer: bus/link``). While the board
  is stopped the switch is busy reconnecting and publishes nothing, so no
  report at all is said as a stopped board too.
* ``/actuo_bus_servicer/servo/state`` (actuo_msgs/ServoState): the joints whose
  servo does not answer (with the bus's reason), the ones without torque,
  faults and joints that would jump on servo ON. This is what RViz shows as
  blinking red links; it reaches the AI TA as text.
* ``/diagnostics``: every status that is not OK.

Every outcome is printed, including "no state" -- an empty section would read
as "all fine".
"""

import argparse
import time

#: The servo switch's status saying whether the board answers.
BOARD_DIAG_NAME = 'actuo_bus_servicer: bus/link'


def _level(value):
    """DiagnosticStatus.level as an int (rclpy gives the byte field as bytes)."""
    return value[0] if isinstance(value, (bytes, bytearray)) else int(value)


def _servo_lines(msg):
    joints = list(msg.joints)
    absent = [j for j in joints if not j.present]
    limp = [j.name for j in joints if j.present and not j.enabled]
    faults = [j for j in joints if j.error]
    jumpy = [j.name for j in joints if j.would_jump]
    lines = ['servo/state: {} joints, {} answering, {} with torque'.format(
        len(joints), len(joints) - len(absent),
        sum(1 for j in joints if j.enabled))]
    if absent:
        lines.append('NOT ANSWERING (servo missing / cable / power): ' + '; '.join(
            '{} ({})'.format(j.name, j.absence_reason or 'no reason given')
            for j in absent))
    else:
        lines.append('all servos answer')
    if limp:
        lines.append('torque OFF (limp): ' + ', '.join(limp))
    if faults:
        lines.append('FAULT: ' + '; '.join(
            '{} error {} {}'.format(j.name, j.error, j.error_name) for j in faults))
    if jumpy:
        lines.append('servo ON would be refused (controller far from pose): '
                     + ', '.join(jumpy))
    lines.append('bus counters: cycles {} error_frames {} unmatched_frames {}'.format(
        msg.cycles, msg.error_frames, msg.unmatched_frames))
    return lines


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--seconds', type=float, default=3.0)
    args = p.parse_args()

    import rclpy
    from rclpy.qos import DurabilityPolicy, QoSProfile
    try:
        from actuo_msgs.msg import ServoState
    except ImportError:
        ServoState = None
    from diagnostic_msgs.msg import DiagnosticArray, DiagnosticStatus

    rclpy.init()
    node = rclpy.create_node('aita_robot_state')
    got = {'servo': None, 'diag': {}}
    if ServoState is not None:
        node.create_subscription(
            ServoState, '/actuo_bus_servicer/servo/state',
            lambda m: got.__setitem__('servo', m),
            QoSProfile(depth=1, durability=DurabilityPolicy.TRANSIENT_LOCAL))

    def on_diag(msg):
        for st in msg.status:
            got['diag'][st.name] = st

    node.create_subscription(DiagnosticArray, '/diagnostics', on_diag, 50)
    end = time.monotonic() + args.seconds
    while time.monotonic() < end:
        rclpy.spin_once(node, timeout_sec=0.1)

    link = got['diag'].get(BOARD_DIAG_NAME)
    board_ok = link is not None and _level(link.level) < _level(DiagnosticStatus.ERROR)
    if link is None:
        print('board: NO REPORT from the servo switch ({}) within {:.0f} s -- either '
              'the board stopped answering (the switch reconnects and publishes '
              'nothing meanwhile: power the robot off and on, then ri.servo_on()) '
              'or no real-robot bring-up is running'.format(BOARD_DIAG_NAME, args.seconds))
    elif _level(link.level) >= _level(DiagnosticStatus.ERROR):
        print('board: STOPPED -- {} (servos are all OFF; power the robot off and on, '
              'then ri.servo_on())'.format(link.message))
    else:
        print('board: answering')

    if ServoState is None:
        print('servo/state: actuo_msgs is not importable (workspace not sourced?)')
    elif got['servo'] is None:
        print('servo/state: nothing on /actuo_bus_servicer/servo/state within '
              '{:.0f} s (no servo switch running, or a different ROS_DOMAIN_ID)'
              .format(args.seconds))
    else:
        if not board_ok:
            # servo/state is transient_local: the last one published, from
            # before the board stopped, is handed to every new subscriber.
            print('(servo/state below may be from before the board stopped)')
        print('\n'.join(_servo_lines(got['servo'])))

    level_name = {_level(DiagnosticStatus.OK): 'OK', _level(DiagnosticStatus.WARN): 'WARN',
                  _level(DiagnosticStatus.ERROR): 'ERROR',
                  _level(DiagnosticStatus.STALE): 'STALE'}
    ok = _level(DiagnosticStatus.OK)
    bad = [st for st in got['diag'].values() if _level(st.level) != ok]
    if not got['diag']:
        print('diagnostics: nothing on /diagnostics within {:.0f} s'.format(args.seconds))
    elif not bad:
        print('diagnostics: {} statuses, all OK'.format(len(got['diag'])))
    else:
        for st in sorted(bad, key=lambda s: -_level(s.level)):
            print('diagnostics {}: {}: {}'.format(
                level_name.get(_level(st.level), _level(st.level)), st.name, st.message))
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
