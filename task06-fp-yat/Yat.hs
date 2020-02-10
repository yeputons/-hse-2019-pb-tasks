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

putTabs :: String -> String
putTabs [] = []
putTabs (s:str) | s == '\n' = concat [[s], "\t", (putTabs str)]
                | otherwise = s : (putTabs str)

showExpr :: Expression -> String
showExpr (Number n) = show n
showExpr (Reference name) = name
showExpr (Assign name e) = concat ["let ", name, " = ", (showExpr e), " tel"]
showExpr (BinaryOperation op l r) = concat ["(", showExpr l, " ", showBinop op, " ", showExpr r, ")"]
showExpr (UnaryOperation op e) = showUnop op ++ showExpr e
showExpr (FunctionCall name []) = name ++ "()"
showExpr (FunctionCall name (x:xs)) = concat [name, "(", showExpr x, concatMap ((++) ", " . showExpr) xs, ")"]
showExpr (Conditional e t f) = concat ["if ", showExpr e, " then ", showExpr t, " else ", showExpr f, " fi"]
showExpr (Block []) = "{\n}"
showExpr (Block (x:xs)) = putTabs (concat ["{\n", showExpr x, concatMap ((++) ";\n" . showExpr) xs]) ++ "\n}"

showFunctionDefenition :: FunctionDefinition -> String
showFunctionDefenition (name, [], def)        = concat ["func ", name, "() = ", showExpr def]
showFunctionDefenition (name, x:names, def) = concat ["func ", name, "(", x, concatMap (", " ++) names, ") = ", showExpr def]

-- Верните текстовое представление программы (см. условие).
showProgram :: Program -> String
showProgram f = concatMap ((++ "\n") . showFunctionDefenition) (fst f) ++ showExpr (snd f)

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

getVar :: State -> Name -> Integer
getVar scope name = snd (head (filter ((==) name . fst) scope))

getFuncDef :: Name -> [FunctionDefinition] -> ([Name], Expression)
getFuncDef name funcs = f (head (filter (eq' name) funcs)) 
                      where eq' name (n, names, e) = name == n
                            f (n, name, e) = (name, e)

createFuncScope :: State -> [Name] -> [Integer] -> State
createFuncScope scope params values = zip params values ++ scope

chainExpr :: [FunctionDefinition] -> State -> [Expression] -> ([Integer], State)
chainExpr funcs scope [] = ([], scope)
chainExpr funcs scope (arg:args) = (fst argres:fst argsres, snd argsres)
                                 where argres = evalExpr  funcs scope arg
                                       argsres = chainExpr funcs (snd argres) args

evalExpr :: [FunctionDefinition] -> State -> Expression -> (Integer, State)
evalExpr funcs scope (Number n) = (n, scope)
evalExpr funcs scope (Reference name) = (getVar scope name, scope)
evalExpr funcs scope (Assign name e) = (fst res, var:snd res)
                                     where res = evalExpr funcs scope e
                                           var = (name, fst res)
evalExpr funcs scope (BinaryOperation op l r) = (toBinaryFunction op (fst lres) (fst rres), snd rres)
                                              where lres = evalExpr funcs scope l
                                                    rres = evalExpr funcs (snd lres) r
evalExpr funcs scope (UnaryOperation op e) = (toUnaryFunction op (fst res), snd res)
                                           where res = evalExpr funcs scope e
evalExpr funcs scope (FunctionCall name args) = (fst (evalExpr funcs (createFuncScope (snd res) (fst func) (fst res)) (snd func)), snd res) 
                                              where func = getFuncDef name funcs
                                                    res = chainExpr funcs scope args
evalExpr funcs scope (Conditional e t f) | toBool (fst er) = tr
                                         | otherwise = fr
                                         where er = evalExpr funcs scope e
                                               tr = evalExpr funcs (snd er) t
                                               fr = evalExpr funcs (snd er) f
evalExpr funcs scope (Block [x]) = evalExpr funcs scope x
evalExpr funcs scope (Block []) = (0, scope)                                         
evalExpr funcs scope (Block (e:es)) = evalExpr funcs (snd (evalExpr funcs scope e)) (Block es)

eval :: Program -> Integer
eval f = fst (evalExpr (fst f) [] (snd f))
