from typing import Callable, Optional
import traceback
from bot import UserHandler
from tictactoe import Player, TicTacToe


class TicTacToeUserHandler(UserHandler):
    """Реализация логики бота для игры в крестики-нолики с одним пользователем."""
    def __init__(self, send_message: Callable[[str], None]) -> None:
        super(TicTacToeUserHandler, self).__init__(send_message)
        self.game: Optional[TicTacToe] = None

    def __player_to_str(self, player: Optional[Player]) -> str:
        if not player:
            return '.'
        elif player == Player.X:
            return 'X'
        else:
            return 'O'

    def __str_to_player(self, s: str) -> Player:
        if s == 'X':
            return Player.X
        elif s == 'O':
            return Player.O
        else:
            raise ValueError

    def handle_message(self, message: str) -> None:
        """Обрабатывает очередное сообщение от пользователя."""
        if message == 'start':
            self.start_game()
            return
        if not self.game:
            self.send_message('Game is not started')
            return

        str_player, str_col, str_row = message.split(maxsplit=3)

        try:
            player = self.__str_to_player(str_player)
        except Exception:  # pylint: disable=W0703
            traceback.print_exc()

        self.make_turn(
            player,
            row=int(str_row),
            col=int(str_col))

    def start_game(self) -> None:
        """Начинает новую игру в крестики-нолики и сообщает об этом пользователю."""
        self.game = TicTacToe()
        self.send_field()

    def make_turn(self, player: Player, *, row: int, col: int) -> None:
        """Обрабатывает ход игрока player в клетку (row, col)."""
        assert self.game
        if not self.game.can_make_turn(player, row=row, col=col):
            self.send_message('Invalid turn')
            return

        self.game.make_turn(player, row=row, col=col)
        self.send_field()
        self.__try_finish()

    def send_field(self) -> None:
        """Отправляет пользователю сообщение с текущим состоянием игры."""
        if not self.game:
            return
        self.send_message('\n'.join(
            [''.join(map(self.__player_to_str, line)) for line in self.game.field]
            ))

    def __try_finish(self) -> None:
        if self.game and self.game.is_finished():
            message = 'Game is finished, '
            winner = self.game.winner()
            if winner:
                message += self.__player_to_str(winner) + ' wins'
            else:
                message += 'draw'
            self.send_message(message)
            self.game = None
