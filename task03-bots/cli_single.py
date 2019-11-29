#!/usr/bin/env python3
import sys
import traceback
from tictactoe_user_handler import TicTacToeUserHandler


def send_message(message: str) -> None:
    print(message)


def main() -> None:
    user_handler = TicTacToeUserHandler(send_message=send_message)
    for line in sys.stdin:
        try:
            message = line.rstrip('\n')
            user_handler.handle_message(message)
        except Exception:  # pylint: disable=W0703
            traceback.print_exc()


if __name__ == '__main__':
    main()
