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

showFunctionWithParams :: Name -> [a] -> (a -> String) -> String
showFunctionWithParams name params showParams = name ++ "(" ++ intercalate ", " (map showParams params) ++ ")"

addTabs :: String -> String
addTabs = intercalate "\n" . map ("\t" ++) . lines

showExpression :: Expression -> String
showExpression (Number          n        ) = show n
showExpression (Reference       name     ) = name
showExpression (Assign          name e   ) = "let " ++ name ++ " = " ++ showExpression e ++ " tel"
showExpression (BinaryOperation op   l  r) = "(" ++ showExpression l ++ " " ++ showBinop op ++ " " ++ showExpression r ++ ")"
showExpression (UnaryOperation  op   e   ) = showUnop op ++ showExpression e
showExpression (FunctionCall    name es  ) = showFunctionWithParams name es showExpression
showExpression (Conditional     e    t  f) = "if " ++ showExpression e ++ " then " ++ showExpression t ++ " else " ++ showExpression f ++ " fi"
showExpression (Block           []       ) = "{\n}"
showExpression (Block           es       ) = "{\n" ++ intercalate ";\n" (map (addTabs . showExpression) es) ++ "\n}"

showFunctionDefinition :: FunctionDefinition -> String
showFunctionDefinition (name, params, e) = "func " ++ showFunctionWithParams name params id ++ " = " ++ showExpression e ++ "\n"

-- Верните текстовое представление программы (см. условие).
showProgram :: Program -> String
showProgram (fs, e) = concatMap showFunctionDefinition fs ++ showExpression e

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

getFirstElement :: (a, b, c) -> a
getFirstElement (el, _, _) = el

findVarInState :: Name -> ((String, Integer) -> Bool)
findVarInState name var = fst var == name  

getFuncDef :: Name -> [FunctionDefinition] -> FunctionDefinition
getFuncDef name = head . filter (\fd -> getFirstElement fd == name)

addVarToState :: Name -> Integer -> State -> State
addVarToState name val st = (name, val):filter (not . findVarInState name) st

addVarsToState :: [(Name, Integer)] -> State -> State
addVarsToState []                 st = st
addVarsToState ((name, val):vars) st = addVarsToState vars $ addVarToState name val st

evalParams :: [(Name, Expression)] -> [FunctionDefinition] -> State -> ([(Name, Integer)], State)
evalParams []                 fds st = ([], st)
evalParams [(name, e)]        fds st = ([(name, val)], newState)
                                       where (val, newState) = evalExpression e fds st
evalParams ((name, e):params) fds st = ((name, val):paramsVals, resState)
                                       where (val, newState) = evalExpression e fds st
                                             (paramsVals, resState) = evalParams params fds newState

evalIfCondition :: (Integer, State) -> Expression -> Expression -> [FunctionDefinition] -> (Integer, State)
evalIfCondition (0, st) t f fds = evalExpression f fds st
evalIfCondition (_, st) t f fds = evalExpression t fds st

evaluate :: Expression -> [FunctionDefinition] -> State -> Integer
evaluate e fds st = fst $ evalExpression e fds st

evalExpression :: Expression -> [FunctionDefinition] -> State -> (Integer, State)
evalExpression (Number          n         ) fds st = (n, st)
evalExpression (Reference       name      ) fds st = (snd $ head $ filter (findVarInState name) st, st) 
evalExpression (Assign          name  e   ) fds st = (val, addVarToState name val newState)
                                                     where (val, newState) = evalExpression e fds st
evalExpression (BinaryOperation op    l  r) fds st = (toBinaryFunction op lVal rVal, newState2)
                                                     where (lVal, newState1) = evalExpression l fds st
                                                           (rVal, newState2) = evalExpression r fds newState1
evalExpression (UnaryOperation  op    e   ) fds st = (toUnaryFunction op val, newState)
                                                     where (val, newState) = evalExpression e fds st
evalExpression (FunctionCall    name  es  ) fds st = (evaluate body fds $ addVarsToState evaledParams newState, newState) 
                                                     where funcDef                  = getFuncDef name fds
                                                           (_, params, body)        = funcDef
                                                           (evaledParams, newState) = evalParams (zip params es) fds st 
evalExpression (Conditional     e     t  f) fds st = evalIfCondition (evalExpression e fds st) t f fds
evalExpression (Block           []        ) fds st = (0, st)
evalExpression (Block           [e]       ) fds st = evalExpression e fds st
evalExpression (Block           (e:es)    ) fds st = evalExpression (Block es) fds $ snd $ evalExpression e fds st

-- Реализуйте eval: запускает программу и возвращает её значение.
eval :: Program -> Integer
eval (fds, e) = evaluate e fds []
