--  Own checks (see tests/SOURCES.txt). Assume Cyk_Algorithm is wrong or does
--  nothing. The reference is a different method: the language of a grammar
--  up to length Max_W is generated top-down by leftmost derivations, merging
--  equal sentential forms and keeping the best log probability of each (CNF
--  forms never shrink, so forms longer than Max_W are dropped). Then, for
--  random CNF grammars over S, A, B, C and terminals a, b:
--  * Recognize (w) = (w is in the generated language) for every w of length
--    1 .. Max_W;
--  * Parse: null exactly for rejected w; for accepted w the tree is a
--    derivation certificate (root = start symbol, every inner node is a
--    binary production of G, every leaf a terminal production, yield = w);
--  * Parse_Weighted: Accepted as above, Best_Log_P = best derivation weight
--    from the reference (dyadic weights, so sums are exact), and the tree is
--    a certificate whose own weight is Best_Log_P;
--  * the same input given with other index origins (Input'First /= 1);
--  * Tree_ToString on hand-built trees, Free_Parse_Tree, Is_In_CNF.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Hash;
with Ada.Containers.Indefinite_Hashed_Maps;
with Cyk_Algorithm; use Cyk_Algorithm;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   type U32 is mod 2 ** 32;
   Lcg : U32 := 20261008;
   function Rand (M : Positive) return Natural is
   begin
      Lcg := Lcg * 1664525 + 1013904223;
      return Natural ((Lcg / 256) mod U32 (M));
   end Rand;

   --  own rule list (converted to both grammar types)
   type Rule is record
      LHS    : Nonterminal;
      Binary : Boolean;
      R1, R2 : Nonterminal;
      T      : Terminal;
      W      : Float;            --  log probability: 0, -0.25, -0.5, -1 or -2
   end record;
   type Rule_List is array (Positive range <>) of Rule;

   Max_W : constant := 6;
   Syms  : constant String := "SABC";
   Terms : constant String := "ab";
   Weights : constant array (0 .. 4) of Float := [0.0, -0.25, -0.5, -1.0, -2.0];

   package Form_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (String, Float, Ada.Strings.Hash, "=");
   use Form_Maps;

   procedure Put_Best (M : in out Map; K : String; W : Float) is
      C : constant Cursor := M.Find (K);
   begin
      if C = No_Element then
         M.Insert (K, W);
      elsif W > Element (C) then
         M.Replace_Element (C, W);
      end if;
   end Put_Best;

   --  terminal strings of length <= Max_W derivable from Start, with their
   --  best derivation weight
   function Language (R : Rule_List; Start : Nonterminal) return Map is
      Frontier, Next, Result : Map;
   begin
      Frontier.Insert ("" & Start, 0.0);
      while not Frontier.Is_Empty loop
         Next.Clear;
         for C in Frontier.Iterate loop
            declare
               F : constant String := Key (C);
               W : constant Float := Element (C);
               K : Natural := 0;
            begin
               for I in F'Range loop
                  if F (I) in 'A' .. 'Z' then
                     K := I;
                     exit;
                  end if;
               end loop;
               if K = 0 then
                  Put_Best (Result, F, W);
               else
                  for X of R loop
                     if X.LHS = F (K) then
                        declare
                           Rhs : constant String := (if X.Binary then X.R1 & X.R2 else "" & X.T);
                           NF  : constant String := F (F'First .. K - 1) & Rhs & F (K + 1 .. F'Last);
                        begin
                           if NF'Length <= Max_W then
                              Put_Best (Next, NF, W + X.W);
                           end if;
                        end;
                     end if;
                  end loop;
               end if;
            end;
         end loop;
         Frontier := Next;
      end loop;
      return Result;
   end Language;

   function To_Grammar (R : Rule_List; Start : Nonterminal) return Grammar is
      G : Grammar (R'Length);
   begin
      G.Count := R'Length;
      G.Start_Sym := Start;
      for I in R'Range loop
         G.Productions (I - R'First + 1) :=
           (if R (I).Binary then (Kind => Binary, LHS => R (I).LHS, RHS_1 => R (I).R1, RHS_2 => R (I).R2)
            else (Kind => Terminal_Prod, LHS => R (I).LHS, RHS_Terminal => R (I).T));
      end loop;
      return G;
   end To_Grammar;

   function To_Weighted (R : Rule_List; Start : Nonterminal) return Weighted_Grammar is
      G : Weighted_Grammar (R'Length);
   begin
      G.Count := R'Length;
      G.Start_Sym := Start;
      for I in R'Range loop
         G.Productions (I - R'First + 1) :=
           (if R (I).Binary
            then (Kind => Binary, LHS => R (I).LHS, Log_Prob => Log_Probability (R (I).W),
                  RHS_1 => R (I).R1, RHS_2 => R (I).R2)
            else (Kind => Terminal_Prod, LHS => R (I).LHS, Log_Prob => Log_Probability (R (I).W),
                  RHS_Terminal => R (I).T));
      end loop;
      return G;
   end To_Weighted;

   --  derivation certificate: returns the yield, sets Ok to False on a node
   --  that is not a production of R, and adds the best weight of each used
   --  production to W
   function Yield (N : Parse_Node_Access; R : Rule_List; Ok : in out Boolean; W : in out Float) return String is
      Best  : Float := -1.0E30;
      Found : Boolean := False;
   begin
      if N = null then
         Ok := False;
         return "";
      end if;
      case N.Kind is
         when Terminal_Node =>
            for X of R loop
               if not X.Binary and then X.LHS = N.Symbol and then X.T = N.Term then
                  Found := True;
                  Best := Float'Max (Best, X.W);
               end if;
            end loop;
            Ok := Ok and then Found;
            W := W + (if Found then Best else 0.0);
            return "" & N.Term;
         when Nonterminal_Node =>
            if N.Left = null or else N.Right = null then
               Ok := False;
               return "";
            end if;
            for X of R loop
               if X.Binary and then X.LHS = N.Symbol and then X.R1 = N.Left.Symbol and then X.R2 = N.Right.Symbol then
                  Found := True;
                  Best := Float'Max (Best, X.W);
               end if;
            end loop;
            Ok := Ok and then Found;
            W := W + (if Found then Best else 0.0);
            declare
               L : constant String := Yield (Parse_Node_Access (N.Left), R, Ok, W);
            begin
               return L & Yield (Parse_Node_Access (N.Right), R, Ok, W);
            end;
      end case;
   end Yield;

   function To_Input (S : String; First : Positive) return Input_String is
      Result : Input_String (First .. First + S'Length - 1);
   begin
      for I in S'Range loop
         Result (First + I - S'First) := S (I);
      end loop;
      return Result;
   end To_Input;

   function Image (R : Rule_List) return String is
     (if R'Length = 0 then ""
      else (if R (R'First).Binary then R (R'First).LHS & ">" & R (R'First).R1 & R (R'First).R2
            else R (R'First).LHS & ">" & R (R'First).T) & " " & Image (R (R'First + 1 .. R'Last)));

   procedure Check_Grammar (R : Rule_List; Start : Nonterminal; Origins : Boolean) is
      Lang : constant Map := Language (R, Start);
      G    : constant Grammar := To_Grammar (R, Start);
      WG   : constant Weighted_Grammar := To_Weighted (R, Start);
      Desc : constant String := "[" & Image (R) & "start " & Start & "]";
      procedure Check_Word (S : String) is
         C    : constant Cursor := Lang.Find (S);
         In_L : constant Boolean := C /= No_Element;
      begin
         for Pass in 1 .. 2 loop
            exit when Pass = 2 and then not Origins;
            declare
               First : constant Positive := (if Pass = 1 then 1 else 7);
               Inp  : constant Input_String := To_Input (S, First);
               What : constant String := Desc & " w=" & S & " first" & First'Image;
            begin
               Expect (Recognize (G, Inp) = In_L, "Recognize " & What);
               declare
                  T  : Parse_Node_Access := Parse (G, Inp);
                  Ok : Boolean := True;
                  W  : Float := 0.0;
               begin
                  if In_L then
                     Expect (T /= null and then T.Symbol = Start and then Yield (T, R, Ok, W) = S and then Ok,
                             "Parse certificate " & What);
                  else
                     Expect (T = null, "Parse of a rejected word returned a tree " & What);
                  end if;
                  Free_Parse_Tree (T);
               end;
               declare
                  Acc : Boolean;
                  BP  : Log_Probability;
                  T   : Parse_Node_Access;
                  Ok  : Boolean := True;
                  W   : Float := 0.0;
               begin
                  Parse_Weighted (WG, Inp, Acc, BP, T);
                  Expect (Acc = In_L, "Parse_Weighted Accepted " & What);
                  if In_L then
                     Expect (Float (BP) = Element (C), "Parse_Weighted best log p " & What & " got" & BP'Image
                             & " want" & Element (C)'Image);
                     Expect (T /= null and then T.Symbol = Start and then Yield (T, R, Ok, W) = S and then Ok
                             and then W = Element (C), "Parse_Weighted certificate " & What);
                  else
                     Expect (T = null, "Parse_Weighted of a rejected word returned a tree " & What);
                  end if;
                  Free_Parse_Tree (T);
               end;
            end;
         end loop;
      end Check_Word;
      procedure Words (Prefix : String) is
      begin
         if Prefix'Length > 0 then
            Check_Word (Prefix);
         end if;
         if Prefix'Length < Max_W then
            for T of Terms loop
               Words (Prefix & T);
            end loop;
         end if;
      end Words;
   begin
      Words ("");
   end Check_Grammar;

   Accepted_Words : Natural := 0;
begin
   --  hand-picked grammars: a^n b^n (S -> AT | AB, T -> SB), balanced
   --  parentheses as a / b, and one with start symbol C
   declare
      AnBn : constant Rule_List :=
        [('S', True, 'A', 'T', 'a', 0.0), ('S', True, 'A', 'B', 'a', -0.5), ('T', True, 'S', 'B', 'a', -0.25),
         ('A', False, 'A', 'A', 'a', 0.0), ('B', False, 'B', 'B', 'b', -1.0)];
      Dyck : constant Rule_List :=
        [('S', True, 'S', 'S', 'a', -1.0), ('S', True, 'L', 'R', 'a', -0.5), ('S', True, 'L', 'X', 'a', -0.25),
         ('X', True, 'S', 'R', 'a', 0.0), ('L', False, 'L', 'L', 'a', 0.0), ('R', False, 'R', 'R', 'b', 0.0)];
      Start_C : constant Rule_List :=
        [('C', True, 'A', 'C', 'a', -0.5), ('C', False, 'C', 'C', 'b', -2.0), ('A', False, 'A', 'A', 'a', 0.0),
         ('A', False, 'A', 'A', 'b', -1.0), ('S', False, 'S', 'S', 'a', 0.0)];
      L : constant Map := Language (AnBn, 'S');
   begin
      --  the reference itself on a^n b^n: exactly ab, aabb, aaabbb
      Expect (Natural (L.Length) = 3 and then L.Contains ("ab") and then L.Contains ("aabb")
              and then L.Contains ("aaabbb"), "reference language of a^n b^n");
      Expect (L.Contains ("aabb") and then L.Element ("aabb") = -0.5 - 0.25 - 2.0,
              "reference weight of aabb: S -> A T, T -> S B, S -> A B, two b at -1");
      Check_Grammar (AnBn, 'S', True);
      Check_Grammar (Dyck, 'S', True);
      Check_Grammar (Start_C, 'C', True);
   end;
   --  random CNF grammars: 3 .. 9 rules over S, A, B, C, terminals a / b,
   --  duplicates allowed (weighted parsing must keep the better one)
   for Trial in 1 .. 250 loop
      declare
         R : Rule_List (1 .. 3 + Rand (7));
      begin
         for I in R'Range loop
            R (I) := (LHS => Syms (Syms'First + Rand (4)), Binary => Rand (2) = 0,
                      R1 => Syms (Syms'First + Rand (4)), R2 => Syms (Syms'First + Rand (4)),
                      T => Terms (Terms'First + Rand (2)), W => Weights (Rand (5)));
         end loop;
         --  at least one terminal rule for S so that some grammars accept
         R (R'First) := (LHS => 'S', Binary => False, R1 => 'S', R2 => 'S',
                         T => Terms (Terms'First + Rand (2)), W => Weights (Rand (5)));
         Check_Grammar (R, 'S', Trial mod 5 = 0);
         Accepted_Words := Accepted_Words + Natural (Language (R, 'S').Length);
      end;
   end loop;
   Expect (Accepted_Words > 1_000, "random grammars accept enough words to matter:" & Accepted_Words'Image);

   --  Tree_ToString on hand-built trees, Free_Parse_Tree
   declare
      Leaf_A : constant Parse_Node_Access := new Parse_Node'(Kind => Terminal_Node, Symbol => 'A', Term => 'a');
      Leaf_B : constant Parse_Node_Access := new Parse_Node'(Kind => Terminal_Node, Symbol => 'B', Term => 'b');
      Root   : Parse_Node_Access := new Parse_Node'(Kind => Nonterminal_Node, Symbol => 'S',
                                                    Left => Leaf_A, Right => Leaf_B);
   begin
      Expect (Tree_ToString (Leaf_A) = "(A -> a)", "Tree_ToString leaf");
      Expect (Tree_ToString (Root) = "(S (A -> a) (B -> b))", "Tree_ToString inner node");
      Expect (Tree_ToString (null) = "()", "Tree_ToString null");
      Free_Parse_Tree (Root);
      Expect (Root = null, "Free_Parse_Tree sets the access to null");
   end;
   --  Is_In_CNF: every representable production (A -> B C or A -> a) is CNF
   for Trial in 1 .. 50 loop
      declare
         R : Rule_List (1 .. 1 + Rand (6));
      begin
         for I in R'Range loop
            R (I) := (LHS => Syms (Syms'First + Rand (4)), Binary => Rand (2) = 0,
                      R1 => Syms (Syms'First + Rand (4)), R2 => Syms (Syms'First + Rand (4)),
                      T => Terms (Terms'First + Rand (2)), W => 0.0);
         end loop;
         Expect (Is_In_CNF (To_Grammar (R, 'S')), "Is_In_CNF");
      end;
   end loop;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (top-down derivation reference, parse-tree certificates)");
end Own_Checks;
