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

addTabs :: String -> String
addTabs []      = []
addTabs (s:str) | s == '\n' = concat [[s], "\t", addTabs str]
                | otherwise = s : addTabs str 

showExpression :: Expression -> String
showExpression (Number num)                 = show num
showExpression (Reference name)             = name
showExpression (Assign name e)              = concat ["let ", name, " = ", showExpression e, " tel"]
showExpression (BinaryOperation op l r)     = concat ["(", showExpression l, " ", showBinop op, " ", showExpression r, ")"]
showExpression (UnaryOperation op e)        = concat [showUnop op, showExpression e]
showExpression (FunctionCall name [])       = name ++ "()"
showExpression (FunctionCall name args)     = concat [name, "(", intercalate ", " (map showExpression args), ")"]
showExpression (Conditional e t f)          = concat ["if ", showExpression e, " then ", showExpression t, " else ", showExpression f, " fi"]
showExpression (Block [])                   = "{\n}"
showExpression (Block exprs)                = addTabs (concat ["{\n", intercalate ";\n" (map showExpression exprs)]) ++ "\n}"

showFuncDef :: FunctionDefinition -> String
showFuncDef (name, params, expr) = concat ["func ", name, "(", intercalate ", " params, ") = ", showExpression expr]

showFuncList :: [FunctionDefinition] -> String
showFuncList = concatMap ((++ "\n") . showFuncDef)

-- Верните текстовое представление программы (см. условие).
showProgram :: Program -> String
showProgram (funcs, expr) = concat [showFuncList funcs, showExpression expr] 

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

getFuncName :: FunctionDefinition -> Name
getFuncName (name, _, _) = name

getFuncParams :: FunctionDefinition -> [Name]
getFuncParams (_, params, _) = params

getFuncExpr :: FunctionDefinition -> Expression
getFuncExpr (_, _, expr) = expr

getFunc :: [FunctionDefinition] -> Name -> FunctionDefinition
getFunc funcs name = fromJust $ find ((== name) . getFuncName) funcs

createNewScopes :: State -> [FunctionDefinition] -> [Name] -> [Expression] -> (State, State)
createNewScopes state _     []         []        = (state, state)
createNewScopes state _     []         (_:_)     = (state, state)
createNewScopes state _     (_:_)      []        = (state, state)
createNewScopes state funcs (p:params) (e:exprs) = (funcScope, mainScope ++ state)
                                           where
                                            (argValue, mainScope) = evalExpr state funcs e
                                            newScope              = (p, argValue) : mainScope
                                            funcScope             = fst $ createNewScopes newScope funcs params exprs  

evalExpr :: State -> [FunctionDefinition] -> Expression -> (Integer, State)
evalExpr state funcs (Number n)               = (n, state)
evalExpr state funcs (Reference name)         = (fromJust $ lookup name state, state)

evalExpr state funcs (Assign name e)          = (eValue, (name, eValue) : newState)
                                                 where (eValue, newState) = evalExpr state funcs e

evalExpr state funcs (BinaryOperation op l r) = (toBinaryFunction op lValue rValue, newState)
                                                 where
                                                  (lValue, firstNewState) = evalExpr state funcs l
                                                  (rValue, newState)      = evalExpr firstNewState funcs r 
evalExpr state funcs (UnaryOperation op e)    = (toUnaryFunction op eValue, newState)
                                                 where
                                                  (eValue, newState) = evalExpr state funcs e                                            
evalExpr state funcs (FunctionCall name args) = (res, mainScope)
                                                 where
                                                  funcExpr               = getFuncExpr $ getFunc funcs name
                                                  funcParams             = getFuncParams $ getFunc funcs name
                                                  (funcScope, mainScope) = createNewScopes state funcs funcParams args
                                                  res = fst $ evalExpr funcScope funcs funcExpr
evalExpr state funcs (Conditional e t f)      | toBool eValue = evalExpr newState funcs t
                                              | otherwise     = evalExpr newState funcs f
                                                where
                                                 (eValue, newState) = evalExpr state funcs e
evalExpr state funcs (Block [])               = (0, state)
evalExpr state funcs (Block [expr])           = evalExpr state funcs expr
evalExpr state funcs (Block (e:exprs))        = evalExpr (snd (evalExpr state funcs e)) funcs (Block exprs)

                                                               
eval :: Program -> Integer
eval (funcs, expr) = fst $ evalExpr [] funcs expr
