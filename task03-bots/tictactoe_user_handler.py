from typing import Callable, Optional
from bot import UserHandler
from tictactoe import Player, TicTacToe


class TicTacToeUserHandler(UserHandler):
    def __init__(self, send_message: Callable[[str], None]) -> None:
        super(TicTacToeUserHandler, self).__init__(send_message)
        self.game: Optional[TicTacToe] = None

    def handle_message(self, message: str) -> None:
        if message == 'start':
            self.start_game()
            return
        if not self.game:
            self.send_message('Game is not started')
            return
        player, col, row = message.split()
        players = {'X': Player['X'], 'O': Player['O']}
        self.make_turn(
            player=players[player],
            row=int(row),
            col=int(col))

    def start_game(self) -> None:
        self.game = TicTacToe()
        self.send_field()

    def make_turn(self, player: Player, *, row: int, col: int) -> None:
        assert self.game
        if self.game.can_make_turn(player, row=row, col=col):
            self.game.make_turn(player, row=row, col=col)
            self.send_field()
        else:
            self.send_message('Invalid turn')
            return

        if self.game.is_finished():
            winner = self.game.winner()
            if winner:
                self.send_message(
                    f'Game is finished, {winner.name} wins')
            else:
                self.send_message('Game is finished, draw')
            self.game = None

    def send_field(self) -> None:
        assert self.game
        field = []
        for row in self.game.field:
            field.append(''.join([cell.name if cell else '.' for cell in row]))
        self.send_message('\n'.join(field))
