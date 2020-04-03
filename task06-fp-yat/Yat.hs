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

showFunctionDefinition :: FunctionDefinition -> String
showFunctionDefinition (name, params, e) = concat ["func ", name, "(", intercalate ", " params, ") = ", showExpression e, "\n"]


showExpression::Expression -> String
showExpression (Number num)                                 = show num
showExpression (Reference name)                             = name
showExpression (Assign name expr)                           = concat ["let ", name, " = ", showExpression expr, " tel"]
showExpression (BinaryOperation op leftExpr rightExpr)      = concat ["(", showExpression leftExpr, " ", showBinop op, " ", showExpression rightExpr, ")"]
showExpression (UnaryOperation op expr)                     = showUnop op ++ showExpression expr 
showExpression (FunctionCall name args)                     = concat [name, "(", intercalate ", " (map showExpression args), ")"]
showExpression (Conditional cond true false)                = concat ["if ", showExpression cond, " then ", showExpression true, " else ", showExpression false, " fi"]
showExpression (Block expr)                                 = concat ["{\n", concatMap (("\t" ++) . (++ "\n")) (lines $ intercalate ";\n" (map showExpression expr)), "}"]


showProgram :: Program -> String
showProgram (funcs, expr) = concatMap showFunctionDefinition funcs ++ showExpression expr

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


getFuncDef :: Name -> [FunctionDefinition] -> ([Name], Expression)
getFuncDef name funcs = fromJust find (\(x:_) -> x == name) funcs

createFuncScope :: State -> [Name] -> [Integer] -> State
createFuncScope scope params vals = zip params vals ++ scope


chainCall::[FunctionDefinition] -> State -> [Expression] -> ([Integer], State)
chainCall func scope []      = ([], scope)
chainCall func scope (x:xs)  = (fst y:fst ys, snd ys)
                                 where y  = evalExpr func scope x
                                       ys = chainCall func (snd y) xs


getVar :: State -> Name -> Integer
getVar scope name = snd (head (filter ((==) name . fst) scope))

evalCond :: Bool -> State -> [FunctionDefinition] -> (Integer, State)
evalCond cond s functions = evalExpr functions s cond
evalExpr :: [FunctionDefinition] -> State -> Expression -> (Integer, State)
evalExpr functions scope (Number num)             = (num, scope)
evalExpr functions scope (Reference name)         = (getVar scope name, scope)
evalExpr functions scope (Assign name e)          = (fst result, var:snd result)
                                                where result = evalExpr functions scope e
                                                      var    = (name, fst result)
evalExpr functions scope (FunctionCall name args) = (fst (evalExpr functions (createFuncScope (snd result) (fst func) (fst result)) (snd func)), snd result) 
                                                where func = getFuncDef name functions
                                                      result = chainCall functions scope args
evalExpr functions scope (UnaryOperation op expr) = (toUnaryFunction op (fst result), snd result)
                                                where result = evalExpr functions scope expr
evalExpr functions scope (BinaryOperation op left right) = (toBinaryFunction op (fst lres) (fst rres), snd rres)
                                                where lres = evalExpr functions scope left
                                                      rres = evalExpr functions (snd lres) right
evalExpr functions scope (Conditional expr true false) = evalCond  (toBool i) s functions
                                                where (i, s) = evalExpr functions scope expr
evalExpr functions scope (Block [x])              = evalExpr functions scope x
evalExpr functions scope (Block [])               = (0, scope)                                         
evalExpr functions scope (Block (x:xs))           = evalExpr functions (snd (evalExpr functions scope x)) (Block xs)


eval :: Program -> Integer
eval program = fst (evalExpr (fst program) [] (snd program))
