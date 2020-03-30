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
showExpression :: Expression -> String
showExpression (Number n)                       = show n
showExpression (Reference name)                 = name
showExpression (Assign name expr)               = concat ["let ", name, " = ", showExpression expr, " tel"]
showExpression (BinaryOperation op expr1 expr2) = concat ["(", showExpression expr1, " ", showBinop op, " ", showExpression expr2, ")"]
showExpression (UnaryOperation op expr)         = showUnop op ++ showExpression expr
showExpression (FunctionCall name exprs)        = concat [name, "(", intercalate ", " (map showExpression exprs), ")"]
showExpression (Conditional e t f)              = concat ["if ", showExpression e, " then ", showExpression t, " else ", showExpression f, " fi"]
showExpression (Block commands)                 = concat ["{\n", concatMap (\line -> concat ["\t", line, "\n"]) $ lines $ intercalate ";\n" $ map showExpression commands, "}"]

showFuncDef :: FunctionDefinition -> String
showFuncDef (name, params, expr) = concat ["func ", name, "(", intercalate ", " params, ") = ", showExpression expr, "\n"]

showProgram :: Program -> String
showProgram (definitions, expr) = concatMap showFuncDef definitions ++ showExpression expr

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
makeScopeForFunction :: FunctionDefinition -> [Expression] -> State -> [FunctionDefinition] -> (State, State)
makeScopeForFunction (_, argNames, _) exprs oldScope funcs = 
    let addArgument (curScope, funcScope) (name, expr) = let (res, nextScope) = evalExpression expr curScope funcs
                                                         in (nextScope, (name, res):funcScope)
        (resScope, resFuncScope) = foldl addArgument (oldScope, []) (zip argNames exprs)
    in (resScope, resFuncScope ++ resScope)

evalExpression :: Expression -> State -> [FunctionDefinition] -> (Integer, State)
evalExpression (Number n) oldScope funcs                       = (n, oldScope)
evalExpression (Reference name) oldScope funcs                 = let (Just val) = lookup name oldScope
                                                                 in (val, oldScope)
evalExpression (Assign name expr) oldScope funcs               = let (assignValue, newScope) = evalExpression expr oldScope funcs
                                                                 in (assignValue, (name, assignValue):newScope)
evalExpression (BinaryOperation op lExpr rExpr) oldScope funcs = let (lResult, afterLeftExpressionScope) = evalExpression lExpr oldScope funcs
                                                                     (rResult, newScope)                 = evalExpression rExpr afterLeftExpressionScope funcs 
                                                                 in (toBinaryFunction op lResult rResult, newScope)
evalExpression (UnaryOperation op expr) oldScope funcs         = let (value, newScope) = evalExpression expr oldScope funcs
                                                                 in (toUnaryFunction op value, newScope)
evalExpression (FunctionCall name exprs) oldScope funcs        = let Just (funcName, funcArgs, funcBody) = find (\(funcName, _, _) -> funcName == name) funcs
                                                                     (newScope, funcScope)               = makeScopeForFunction (funcName, funcArgs, funcBody) exprs oldScope funcs
                                                                     (rv, _)                             = evalExpression funcBody funcScope funcs
                                                                 in (rv, newScope)
evalExpression (Conditional e t f) oldScope funcs              = let (exprValue, newScope) = evalExpression e oldScope funcs
                                                                 in evalExpression (if toBool exprValue then t else f) newScope funcs 
evalExpression (Block commands) oldScope funcs                 = foldl (\(_, tmpScope) expr -> evalExpression expr tmpScope funcs) (0, oldScope) commands

eval :: Program -> Integer
eval (definitions, expr) = fst (evalExpression expr [] definitions)
