--  Own checks (see tests/SOURCES.txt). Assume Unify is wrong or does
--  nothing. Random pairs of small terms over variables x, y, z, constants
--  k, m and the binary symbol f (some function nodes have a missing left or
--  right argument, as the engine allows). Terms are also held in this file's own
--  tree representation, so nothing below trusts the engine's view of them.
--  * Unifier: apply the engine's answer to both terms and compare the
--    results syntactically (own comparison, through Kind_Of / Name_Of /
--    Left_Of / Right_Of);
--  * idempotence: applying the answer again changes nothing;
--  * brute force: every ground substitution of x, y, z by the 7 ground
--    terms of depth <= 2 over k and f (343 substitutions) is tried with the
--    own representation. If one unifies the pair, Unify must succeed
--    (completeness), and every such ground unifier theta must factor
--    through the answer sigma: theta (sigma (v)) = theta (v) for each
--    variable (most general);
--  * occurs check: x against f (x, k) and similar must fail.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Unification_Engine; use Unification_Engine;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   --  own term representation: a node table
   type Kind is (V, K, F, Nil);
   type Node is record
      Tag   : Kind := Nil;
      Name  : Character := ' ';
      L, R  : Natural := 0;
   end record;
   Nodes : array (1 .. 4000) of Node;
   Used  : Natural := 0;

   function New_Node (N : Node) return Positive is
   begin
      Used := Used + 1;
      Nodes (Used) := N;
      return Used;
   end New_Node;

   Vars : constant array (1 .. 3) of Character := ['x', 'y', 'z'];

   function Random_Term (Depth : Natural) return Positive is
      C : constant Integer := Rand (1, (if Depth = 0 then 5 else 8));
   begin
      case C is
         when 1 .. 3 => return New_Node ((V, Vars (C), 0, 0));
         when 4      => return New_Node ((K, 'k', 0, 0));
         when 5      => return New_Node ((K, 'm', 0, 0));
         when others =>
            declare
               A : constant Natural := (if Rand (1, 6) = 1 then 0 else Random_Term (Depth - 1));
               B : constant Natural := (if Rand (1, 6) = 1 then 0 else Random_Term (Depth - 1));
            begin
               return New_Node ((F, 'f', A, B));
            end;
      end case;
   end Random_Term;

   --  build an own term in the engine's pool
   function To_Engine (T : Natural) return Term_Id is
      Id : Allocated_Id;
   begin
      if T = 0 then
         return Null_Term;
      end if;
      case Nodes (T).Tag is
         when V   => Make_Variable (Nodes (T).Name, Id);
         when K   => Make_Constant (Nodes (T).Name, Id);
         when F   =>
            declare
               A : constant Term_Id := To_Engine (Nodes (T).L);
               B : constant Term_Id := To_Engine (Nodes (T).R);
            begin
               Make_Function ('f', A, B, Id);
            end;
         when Nil => return Null_Term;
      end case;
      return Id;
   end To_Engine;

   --  engine term -> own term
   function From_Engine (T : Term_Id) return Natural is
   begin
      if T = Null_Term then
         return 0;
      end if;
      case Kind_Of (T) is
         when Is_Variable => return New_Node ((V, Name_Of (T), 0, 0));
         when Is_Constant => return New_Node ((K, Name_Of (T), 0, 0));
         when Is_Function =>
            declare
               A : constant Natural := From_Engine (Left_Of (T));
               B : constant Natural := From_Engine (Right_Of (T));
            begin
               return New_Node ((F, Name_Of (T), A, B));
            end;
      end case;
   end From_Engine;

   function Equal (A, B : Natural) return Boolean is
     (if A = 0 or else B = 0 then A = B
      else Nodes (A).Tag = Nodes (B).Tag and then Nodes (A).Name = Nodes (B).Name
           and then Equal (Nodes (A).L, Nodes (B).L) and then Equal (Nodes (A).R, Nodes (B).R));

   --  a symbol clash at a position with no variable above it: no
   --  substitution can make the terms equal (a sound failure certificate)
   function Contains_Var (T : Natural; Name : Character) return Boolean is
     (T /= 0 and then ((Nodes (T).Tag = V and then Nodes (T).Name = Name)
                       or else Contains_Var (Nodes (T).L, Name) or else Contains_Var (Nodes (T).R, Name)));

   --  or a variable facing a non-variable term that contains it (cycle)
   function Clash (A, B : Natural) return Boolean is
     (if A = 0 or else B = 0 then A /= B
      elsif Nodes (A).Tag = V and then Nodes (B).Tag = V then False
      elsif Nodes (A).Tag = V then Contains_Var (B, Nodes (A).Name)
      elsif Nodes (B).Tag = V then Contains_Var (A, Nodes (B).Name)
      elsif Nodes (A).Tag /= Nodes (B).Tag or else Nodes (A).Name /= Nodes (B).Name then True
      else Clash (Nodes (A).L, Nodes (B).L) or else Clash (Nodes (A).R, Nodes (B).R));

   function Size (A : Natural) return Natural is
     (if A = 0 then 0 else 1 + Size (Nodes (A).L) + Size (Nodes (A).R));

   --  ground terms of depth <= 2 over k and f
   Ground : array (1 .. 7) of Positive;
   type Theta is array (1 .. 3) of Positive;

   function Ground_Apply (T : Natural; Th : Theta) return Natural is
   begin
      if T = 0 then
         return 0;
      end if;
      case Nodes (T).Tag is
         when V =>
            for I in Vars'Range loop
               if Vars (I) = Nodes (T).Name then
                  return Th (I);
               end if;
            end loop;
            return T;
         when F =>
            declare
               A : constant Natural := Ground_Apply (Nodes (T).L, Th);
               B : constant Natural := Ground_Apply (Nodes (T).R, Th);
            begin
               return New_Node ((F, Nodes (T).Name, A, B));
            end;
         when others => return T;
      end case;
   end Ground_Apply;

   type Pair is array (1 .. 2) of Positive;
   type Pairs is array (Positive range <>) of Pair;

   Unifiable_Agree, Unifiable_Total, Fail_Answers, Fail_Unconfirmed, Space_Skips : Natural := 0;

   procedure Check_Pair (A, B : Positive; Label : String) is
      Mark : constant Natural := Used;
      Env  : Substitution;
      EA, EB, RA, RB, RRA : Term_Id;
      OK, OK1, OK2, OK3 : Boolean;
      Some_Unifier : Boolean := False;
   begin
      Reset_Pool;
      Clear (Env);
      if Size (A) + Size (B) > 14 then
         Space_Skips := Space_Skips + 1;
         return;
      end if;
      EA := To_Engine (A);
      EB := To_Engine (B);
      Unify (EA, EB, Env, OK);
      --  brute force over ground substitutions
      for I in Ground'Range loop
         for J in Ground'Range loop
            for L in Ground'Range loop
               declare
                  Th : constant Theta := [Ground (I), Ground (J), Ground (L)];
                  M2 : constant Natural := Used;
               begin
                  if Equal (Ground_Apply (A, Th), Ground_Apply (B, Th)) then
                     Some_Unifier := True;
                     if OK then   --  most general: theta (sigma (v)) = theta (v)
                        for Q in Vars'Range loop
                           declare
                              VId, SV : Term_Id;
                              Sp : Boolean;
                           begin
                              if Space_Left < 2 then
                                 exit;
                              end if;
                              Make_Variable (Vars (Q), VId);
                              Apply_Substitution (VId, Env, SV, Sp);
                              if Sp and then not Equal (Ground_Apply (From_Engine (SV), Th), Th (Q)) then
                                 Fail (Label & ": answer is not most general (ground unifier does not factor through it)");
                              end if;
                           end;
                        end loop;
                     end if;
                  end if;
                  Used := M2;
               end;
            end loop;
         end loop;
      end loop;
      if Some_Unifier then
         Unifiable_Total := Unifiable_Total + 1;
         if OK then
            Unifiable_Agree := Unifiable_Agree + 1;
         else
            Fail (Label & ": Unify failed but a ground unifier exists");
         end if;
      end if;
      if OK and then Clash (A, B) then
         Fail (Label & ": unified a pair that has a clash or cycle certificate");
      end if;
      if OK then
         Apply_Substitution (EA, Env, RA, OK1);
         Apply_Substitution (EB, Env, RB, OK2);
         if OK1 and then OK2 then
            if not Equal (From_Engine (RA), From_Engine (RB)) then
               Fail (Label & ": applying the answer does not make the terms identical");
            end if;
            Apply_Substitution (RA, Env, RRA, OK3);
            if OK3 and then not Equal (From_Engine (RRA), From_Engine (RA)) then
               Fail (Label & ": answer is not idempotent");
            end if;
         else
            Space_Skips := Space_Skips + 1;
         end if;
      else
         Fail_Answers := Fail_Answers + 1;
         if not Some_Unifier and then not Clash (A, B) then
            Fail_Unconfirmed := Fail_Unconfirmed + 1;   --  no clash, no depth-2 unifier
         end if;
      end if;
      Used := Mark;
   end Check_Pair;

begin
   declare
      Kk : constant Positive := New_Node ((K, 'k', 0, 0));
      F1 : constant Positive := New_Node ((F, 'f', Kk, Kk));
   begin
      Ground := [Kk, F1, New_Node ((F, 'f', Kk, F1)), New_Node ((F, 'f', F1, Kk)),
                 New_Node ((F, 'f', F1, F1)), New_Node ((F, 'f', Kk, 0)), New_Node ((F, 'f', 0, Kk))];
   end;
   for Round in 1 .. 400 loop
      declare
         A : constant Positive := Random_Term (2);
         B : constant Positive := Random_Term (2);
      begin
         Check_Pair (A, B, "pair#" & Round'Image);
      end;
   end loop;
   --  occurs check: x = f (x, k), x = f (k, f (x, k)), f (x, y) = f (y, f (x, k))
   declare
      X  : constant Positive := New_Node ((V, 'x', 0, 0));
      Y  : constant Positive := New_Node ((V, 'y', 0, 0));
      Kk : constant Positive := New_Node ((K, 'k', 0, 0));
      FX : constant Positive := New_Node ((F, 'f', X, Kk));
      Before : constant Natural := Unifiable_Agree;
   begin
      for P of Pairs'[[X, FX], [X, New_Node ((F, 'f', Kk, FX))],
                      [New_Node ((F, 'f', X, Y)), New_Node ((F, 'f', Y, FX))]] loop
         declare
            Env : Substitution;
            OK  : Boolean;
         begin
            Reset_Pool;
            Clear (Env);
            Unify (To_Engine (P (1)), To_Engine (P (2)), Env, OK);
            if OK then
               Fail ("occurs check: cyclic pair unified");
            end if;
         end;
      end loop;
      pragma Assert (Before = Unifiable_Agree);
   end;
   --  Symbols that share a letter with a variable, and kind clashes between
   --  a constant and a function with the same name. A constant or function
   --  named 'x' is not the variable x, so a binding of x must not affect it;
   --  a constant never unifies with a function term, whatever the names.
   --  Expected answers follow from the definition of syntactic unification.
   declare
      Env : Substitution;
      OK  : Boolean;
      Xv, Kc, Xc1, Xc2, Fx1, Fx2, Fc, Ff, Fn, Yv, Fk : Term_Id;
   begin
      Reset_Pool;
      Make_Variable ('x', Xv);
      Make_Constant ('k', Kc);
      Make_Constant ('x', Xc1);
      Make_Constant ('x', Xc2);
      Make_Function ('x', Kc, Kc, Fx1);
      Make_Function ('x', Kc, Kc, Fx2);
      Make_Constant ('f', Fc);
      Make_Function ('f', Kc, Kc, Ff);
      Make_Function ('f', Null_Term, Null_Term, Fn);
      Clear (Env);
      Env.Bindings ('x') := Kc;          --  x := k
      Env.Bindings ('f') := Kc;          --  f := k (variable f, unrelated to symbol f)
      Unify (Xc1, Xc2, Env, OK);
      if not OK then
         Fail ("constant x vs constant x with variable x bound");
      end if;
      Unify (Fx1, Fx2, Env, OK);
      if not OK then
         Fail ("function x(k,k) vs x(k,k) with variable x bound");
      end if;
      Unify (Xc1, Xv, Env, OK);          --  x is k, so this is constant x vs k
      if OK then
         Fail ("constant x unified with variable x bound to k");
      end if;
      Unify (Fc, Ff, Env, OK);
      if OK then
         Fail ("constant f unified with function f(k,k)");
      end if;
      Unify (Ff, Fc, Env, OK);
      if OK then
         Fail ("function f(k,k) unified with constant f");
      end if;
      Unify (Fn, Fc, Env, OK);
      if OK then
         Fail ("function f(_,_) unified with constant f");
      end if;
      Unify (Fc, Fn, Env, OK);
      if OK then
         Fail ("constant f unified with function f(_,_)");
      end if;

      --  Hand-built cyclic environments (Substitution is a public record):
      --  Apply_Substitution must terminate and report failure.
      Reset_Pool;
      Make_Variable ('x', Xv);
      Make_Variable ('y', Yv);
      Make_Constant ('k', Kc);
      Make_Function ('f', Kc, Xv, Fk);   --  f(k, x)
      Clear (Env);
      Env.Bindings ('x') := Yv;
      Env.Bindings ('y') := Xv;          --  x -> y -> x
      Apply_Substitution (Xv, Env, Fx1, OK);
      if OK then
         Fail ("apply with binding cycle x -> y -> x succeeded");
      end if;
      Clear (Env);
      Env.Bindings ('x') := Fk;          --  x -> f(k, x)
      Apply_Substitution (Xv, Env, Fx1, OK);
      if OK then
         Fail ("apply with cycle x -> f(k, x) succeeded");
      end if;
   end;
   Put_Line ("own checks: unifiable pairs (ground unifier exists)" & Unifiable_Agree'Image & " /" & Unifiable_Total'Image
     & ", Unify failures" & Fail_Answers'Image & " (no clash or cycle certificate:" & Fail_Unconfirmed'Image
     & "), skipped for pool size" & Space_Skips'Image);
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
