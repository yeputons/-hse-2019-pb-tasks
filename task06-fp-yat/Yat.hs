module Yat where  -- Вспомогательная строчка, чтобы можно было использовать функции в других файлах.
import Data.List
import Data.Maybe
import Data.Bifunctor
import Debug.Trace

-- В логических операциях 0 считается ложью, всё остальное - истиной.
-- При этом все логические операции могут вернуть только 0 или 1.

-- Все возможные бинарные операции: сложение, умножение, вычитание, деление, взятие по модулю, <, <=, >, >=, ==, !=, логическое &&, логическое ||
data Binop = Add | Mul | Sub | Div | Mod | Lt | Le | Gt | Ge | Eq | Ne | And | Or

-- Все возможные унарные операции: смена знака числа и логическое "не".
data Unop = Neg | Not

data Expression = Number Integer  -- Возвращает число, побочных эффектов нет.
                | Reference Name  -- Возвращает значение соответствующей переменной в текущем scope, побочных эффектов нет.
                | Assign Name Expression  -- Вычисляет операнд, а потом изменяет значение соответствующей переменной и возвращает его. Если соответствующей переменной нет, она создаётся.
                | BinaryOperation Binop Expression Expression  -- Вычисляет сначала левый операнд, потом правый, потом возвращает результат операции. Других побочных эффектов нет.
                | UnaryOperation Unop Expression  -- Вычисляет операнд, потом применяет операцию и возвращает результат. Других побочных эффектов нет.
                | FunctionCall Name [Expression]  -- Вычисляет аргументы от первого к последнему в текущем scope, потом создаёт новый scope для дочерней функции (копию текущего с добавленными параметрами), возвращает результат работы функции.
                | Conditional Expression Expression Expression -- Вычисляет первый Expression, в случае истины вычисляет второй Expression, в случае лжи - третий. Возвращает соответствующее вычисленное значение.
                | Block [Expression] -- Вычисляет в текущем scope все выражения по очереди от первого к последнему, результат вычисления -- это результат вычисления последнего выражения или 0, если список пуст.

type Name = String
type FunctionDefinition = (Name, [Name], Expression)  -- Имя функции, имена параметров, тело функции
type State = [(String, Integer)]  -- Список пар (имя переменной, значение). Новые значения дописываются в начало, а не перезаписываютсpя
type Program = ([FunctionDefinition], Expression)  -- Все объявленные функций и основное тело программы

showBinop :: Binop -> String
showBinop Add = "+"
showBinop Mul = "*"
showBinop Sub = "-"
showBinop Div = "/"
showBinop Mod = "%"
showBinop Lt  = "<"
showBinop Le  = "<="
showBinop Gt  = ">"
showBinop Ge  = ">="
showBinop Eq  = "=="
showBinop Ne  = "/="
showBinop And = "&&"
showBinop Or  = "||"

showUnop :: Unop -> String
showUnop Neg = "-"
showUnop Not = "!"

-- Верните текстовое представление программы (см. условие).


putTabs :: String -> String
putTabs []          = []
putTabs (string:str) | string == '\n' = concat [[string], "\t", putTabs str]
                     | otherwise = string:putTabs str

showExpr :: Expression -> String
showExpr (Number number)                   = show number
showExpr (Reference name)                  = name
showExpr (Assign name _Expr)               = concat ["let ", name, " = ", showExpr _Expr, " tel"]
showExpr (BinaryOperation op left right)   = concat ["(", showExpr left, " ", showBinop op, " ", showExpr right, ")"]
showExpr (UnaryOperation op _Expr)         = showUnop op ++ showExpr _Expr
showExpr (FunctionCall name [])            = name ++ "()"
showExpr (FunctionCall name (x:xs))        = concat [name, "(", showExpr x, concatMap ((++) ", " . showExpr) xs, ")"]
showExpr (Conditional _Expr t f)           = concat ["if ", showExpr _Expr, " then ", showExpr t, " else ", showExpr f, " fi"]
showExpr (Block [])                        = "{\n}"
showExpr (Block (x:xs))                    = putTabs (concat ["{\n", showExpr x, concatMap ((++) ";\n" . showExpr) xs]) ++ "\n}"

showFunct :: FunctionDefinition -> String
showFunct (name, [], def)      = concat ["func ", name, "() = ", showExpr def]
showFunct (name, x:names, def) = concat ["func ", name, "(", x, concatMap (", " ++) names, ") = ", showExpr def]

showProgram :: Program -> String
showProgram (f, _Expr) = concatMap ((++ "\n") . showFunct) f ++ showExpr _Expr


toBool :: Integer -> Bool
toBool = (/=) 0

fromBool :: Bool -> Integer
fromBool False = 0
fromBool True  = 1

toBinaryFunction :: Binop -> Integer -> Integer -> Integer
toBinaryFunction Add = (+)
toBinaryFunction Mul = (*)
toBinaryFunction Sub = (-)
toBinaryFunction Div = div
toBinaryFunction Mod = mod
toBinaryFunction Lt  = (.) fromBool . (<)
toBinaryFunction Le  = (.) fromBool . (<=)
toBinaryFunction Gt  = (.) fromBool . (>)
toBinaryFunction Ge  = (.) fromBool . (>=)
toBinaryFunction Eq  = (.) fromBool . (==)
toBinaryFunction Ne  = (.) fromBool . (/=)
toBinaryFunction And = \l r -> fromBool $ toBool l && toBool r
toBinaryFunction Or  = \l r -> fromBool $ toBool l || toBool r

toUnaryFunction :: Unop -> Integer -> Integer
toUnaryFunction Neg = negate
toUnaryFunction Not = fromBool . not . toBool

-- Если хотите дополнительных баллов, реализуйте
-- вспомогательные функции ниже и реализуйте evaluate через них.
-- По минимуму используйте pattern matching для `Eval`, функции
-- `runEval`, `readState`, `readDefs` и избегайте явной передачи состояния.

{- -- Удалите эту строчку, если решаете бонусное задание.
newtype Eval a = Eval ([FunctionDefinition] -> State -> (a, State))  -- Как data, только эффективнее в случае одного конструктора.

runEval :: Eval a -> [FunctionDefinition] -> State -> (a, State)
runEval (Eval f) = f

evaluated :: a -> Eval a  -- Возвращает значение без изменения состояния.
evaluated = undefined

readState :: Eval State  -- Возвращает состояние.
readState = undefined

addToState :: String -> Integer -> a -> Eval a  -- Добавляет/изменяет значение переменной на новое и возвращает константу.
addToState = undefined

readDefs :: Eval [FunctionDefinition]  -- Возвращает все определения функций.
readDefs = undefined

andThen :: Eval a -> (a -> Eval b) -> Eval b  -- Выполняет сначала первое вычисление, а потом второе.
andThen = undefined

andEvaluated :: Eval a -> (a -> b) -> Eval b  -- Выполняет вычисление, а потом преобразует результат чистой функцией.
andEvaluated = undefined

evalExpressionsL :: (a -> Integer -> a) -> a -> [Expression] -> Eval a  -- Вычисляет список выражений от первого к последнему.
evalExpressionsL = undefined

evalExpression :: Expression -> Eval Integer  -- Вычисляет выражение.
evalExpression = undefined
-} -- Удалите эту строчку, если решаете бонусное задание.

-- Реализуйте eval: запускает программу и возвращает её значение.


getValue :: State -> Name -> Integer
getValue []                 _ = 0
getValue ((x, xs):scope) name | name == x = xs
                              | otherwise = getValue scope name

parser :: [FunctionDefinition] -> State -> FunctionDefinition -> [Expression] -> (State, State)
parser         _ _ (_, _:_, _)[]                             = ([], [])
parser funct scope (_, [], _) _                              = (scope, scope)
parser funct scope (fName, _name : _names, fExpr) (arg:args) = (fst res, fst evalres ++ scope)
                                                                          where evalres      = evalExpression funct scope arg
                                                                                function     = (fName, _names, fExpr) 
                                                                                _scope       = (_name, snd evalres) : fst evalres
                                                                                res          = parser funct _scope function args

evalExpression :: [FunctionDefinition] -> State -> Expression -> (State, Integer)

evalExpression funct scope (Number number)   = (scope, number) 

evalExpression funct scope (Reference name)  = (scope, getValue scope name)

evalExpression funct scope (Assign name arg) = 
                                              let res = evalExpression funct scope arg
                                                  first = fst res
                                                  second = snd res
                                                  in ((name, second):first, second)

evalExpression funct scope (BinaryOperation o left right) =
                                                            let first   = fst res
                                                                second  = snd res
                                                                first'  = fst res'
                                                                second' = snd res'
                                                                res     = evalExpression funct first' right
                                                                res'    = evalExpression funct scope left
                                                                in (first, toBinaryFunction o second' second)

evalExpression funct scope (UnaryOperation o arg) = (fst (evalExpression funct scope arg), toUnaryFunction o $ snd $ evalExpression funct scope arg)               

evalExpression [] _ (FunctionCall _ _) = ([], 0)

evalExpression ((funcName, funcArgs, funcExpr):funct) scope (FunctionCall name args)| funcName /= name = evalExpression f scope $ FunctionCall name args
                                                                                    | otherwise        = (second_scope, second_res)
                                                                                    where func         = (funcName, funcArgs, funcExpr)
                                                                                          f            = funct ++ [func]
                                                                                          second_res   = snd res
                                                                                          second_scope = snd _scope
                                                                                          _scope       = parser f scope func args
                                                                                          res          = evalExpression f (fst _scope) funcExpr

evalExpression funct scope (Conditional arg true false)                             | toBool second     = evalExpression funct first true
                                                                                    | otherwise         = evalExpression funct first false
                                                                                     where  first       = fst cond
                                                                                            second      = snd cond
                                                                                            cond        = evalExpression funct scope arg

evalExpression funct scope (Block [])                                                 = (scope, 0)
evalExpression funct scope (Block [x])                                                = evalExpression funct scope x
evalExpression funct scope (Block (x:xs))                                             = evalExpression funct (fst $ evalExpression funct scope x) (Block xs)

eval :: Program -> Integer
eval (funct, expression) = snd $ evalExpression funct [] expression