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

addTab :: String -> String
addTab [] = []
addTab (l:other) | l == '\n' = l : '\t' : addTab other
                 | otherwise = l : addTab other

showExpr :: Expression -> String
showExpr (Number          n               ) = show n
showExpr (Reference       name            ) = name 
showExpr (Assign          name expr       ) = concat ["let ", name, " = ", showExpr expr, " tel"]
showExpr (BinaryOperation op   l    r     ) = "(" ++ showExpr l ++ " " ++ showBinop op ++ " " ++ showExpr r ++ ")"
showExpr (UnaryOperation  oper expr       ) = showUnop oper ++ showExpr expr
showExpr (FunctionCall    name []         ) = name ++ "()"
showExpr (FunctionCall    name (fst:other)) = concat [name, "(", showExpr fst, concatMap ((++) ", " . showExpr) other, ")"]
showExpr (Conditional     expr t    f     ) = concat ["if ", showExpr expr, " then ", showExpr t, " else ", showExpr f, " fi"]
showExpr (Block []                        ) = "{\n}"
showExpr (Block           (fst:other)     ) = addTab (concat ["{\n", showExpr fst, concatMap ((++) ";\n" . showExpr) other]) ++ "\n}"

showFunc ::  FunctionDefinition -> String
showFunc (name, [], expr         ) = concat ["func ", name, "() =", showExpr expr] 
showFunc (name, fst : other, expr) = concat ["func ", name, "(", fst, concatMap (", " ++) other, ") = ", showExpr expr]

showProgram :: Program -> String
showProgram (funcs, expr) = concatMap ((++ "\n") . showFunc) funcs ++ showExpr expr

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

getVar :: State -> Name -> Integer
getVar scope name = snd (head (filter ((==) name . fst) scope))

getFuncDef :: Name -> [FunctionDefinition] -> ([Name], Expression)
getFuncDef name funcs = f (head (filter (eq' name) funcs)) 
                        where eq' name (n, names, e) = name == n
                              f   (n, name, e)       = (name, e)

createFuncScope :: State -> [Name] -> [Integer] -> State
createFuncScope scope params values = zip params values ++ scope

chainExpr :: [FunctionDefinition] -> State -> [Expression] -> ([Integer], State)
chainExpr funcs scope []         = ([], scope)
chainExpr funcs scope (arg:args) = (fst argans:fst argsans, snd argsans)
                                    where argans  = evalExpr  funcs scope        arg
                                          argsans = chainExpr funcs (snd argans) args

evalExpr :: [FunctionDefinition] -> State -> Expression -> (Integer, State)
evalExpr funcs scope (Number          num        ) = (num, scope)
evalExpr funcs scope (Reference       name       ) = (getVar scope name, scope)
evalExpr funcs scope (Assign          name expr  ) = (int, (name, int):state)
                                                     where (int, state  ) = evalExpr funcs scope expr 

evalExpr funcs scope (BinaryOperation oper l    r) = (toBinaryFunction oper int1 int2, state2)
                                                     where (int1, state1) = evalExpr funcs scope l
                                                           (int2, state2) = evalExpr funcs state1 r

evalExpr funcs scope (UnaryOperation  oper expr  ) = (toUnaryFunction oper int, state)
                                                     where (int, state  ) = evalExpr funcs scope expr

evalExpr funcs scope (FunctionCall    name args  ) = (fst (evalExpr funcs (createFuncScope (snd ans) (fst func) (fst ans)) (snd func)), snd ans) 
                                                     where func = getFuncDef name funcs
                                                           ans  = chainExpr funcs scope args

evalExpr funcs scope (Conditional     expr t    f) | toBool int = evalExpr funcs state t
                                                   | otherwise  = evalExpr funcs state f
                                                     where (int, state  ) = evalExpr funcs scope expr 

evalExpr funcs scope (Block []    )                = (0, scope)
evalExpr funcs scope (Block [x]   )                = evalExpr funcs scope x
evalExpr funcs scope (Block (x:xs))                = evalExpr funcs (snd (evalExpr funcs scope x)) (Block xs)

eval :: Program -> Integer
eval f = fst (evalExpr (fst f) [] (snd f))