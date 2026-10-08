--------------------------------------------------------------------------------
-- Package Body: Cyk_Algorithm
-- Implementation of standard CYK recognition, parse tree generation, and
-- weighted CYK parsing.
--------------------------------------------------------------------------------

with Ada.Unchecked_Deallocation;

package body Cyk_Algorithm is

   -- The parse tree strictly uses anonymous access types (access Parse_Node) for Left/Right
   -- components to prevent named access type proliferation. We suppress the warning for
   -- anonymous access allocators globally in this body.
   pragma Warnings (Off, "-gnatw_a");

   ----------------------------------------------------------------------------
   -- Is_In_CNF Implementation
   ----------------------------------------------------------------------------
   function Is_In_CNF (G : Grammar) return Boolean is
   begin
      for I in 1 .. G.Count loop
         declare
            Prod : Production renames G.Productions (I);
         begin
            case Prod.Kind is
               when Binary =>
                  null; -- Valid CNF form
               when Terminal_Prod =>
                  null; -- Valid CNF form
            end case;
         end;
      end loop;
      return True;
   end Is_In_CNF;

   ----------------------------------------------------------------------------
   -- Recognize Implementation (Variant 1)
   ----------------------------------------------------------------------------
   function Recognize (G : Grammar; Input : Input_String) return Boolean is
      N : constant Natural := Input'Length;
      type Table_Type is array (1 .. N, 1 .. N, Nonterminal) of Boolean;
      P : Table_Type := [others => [others => [others => False]]];
   begin
      -- 1. Base case: length 1 substrings (terminal productions)
      for S_Idx in 1 .. N loop
         for P_Idx in 1 .. G.Count loop
            declare
               Prod : Production renames G.Productions (P_Idx);
            begin
               if Prod.Kind = Terminal_Prod and then Prod.RHS_Terminal = Input (S_Idx) then
                  P (1, S_Idx, Prod.LHS) := True;
               end if;
            end;
         end loop;
      end loop;

      -- 2. Recursive steps: lengths 2 to N
      for L in 2 .. N loop
         for S_Idx in 1 .. N - L + 1 loop
            for Part in 1 .. L - 1 loop
               for P_Idx in 1 .. G.Count loop
                  declare
                     Prod : Production renames G.Productions (P_Idx);
                  begin
                     if Prod.Kind = Binary then
                        if P (Part, S_Idx, Prod.RHS_1) and then
                           P (L - Part, S_Idx + Part, Prod.RHS_2) then
                           P (L, S_Idx, Prod.LHS) := True;
                        end if;
                     end if;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;

      -- 3. Accept if start symbol can generate string of length N starting at index 1
      return P (N, 1, G.Start_Sym);
   end Recognize;

   ----------------------------------------------------------------------------
   -- Parse Implementation (Variant 2)
   ----------------------------------------------------------------------------
   function Parse (G : Grammar; Input : Input_String) return Parse_Node_Access is
      N : constant Natural := Input'Length;

      type Cell_Data is record
         Valid : Boolean := False;
         Node  : Parse_Node_Access := null;
      end record;

      type Table_Parse is array (1 .. N, 1 .. N, Nonterminal) of Cell_Data;
      P : Table_Parse := [others => [others => [others => (Valid => False, Node => null)]]];
   begin
      -- 1. Base case: length 1
      for S_Idx in 1 .. N loop
         for P_Idx in 1 .. G.Count loop
            declare
               Prod : Production renames G.Productions (P_Idx);
            begin
               if Prod.Kind = Terminal_Prod and then Prod.RHS_Terminal = Input (S_Idx) then
                  P (1, S_Idx, Prod.LHS).Valid := True;
                  P (1, S_Idx, Prod.LHS).Node := new Parse_Node'(Kind   => Terminal_Node,
                                                                 Symbol => Prod.LHS,
                                                                 Term   => Input (S_Idx));
               end if;
            end;
         end loop;
      end loop;

      -- 2. Recursive steps: lengths 2 to N
      for L in 2 .. N loop
         for S_Idx in 1 .. N - L + 1 loop
            for Part in 1 .. L - 1 loop
               for P_Idx in 1 .. G.Count loop
                  declare
                     Prod : Production renames G.Productions (P_Idx);
                  begin
                     if Prod.Kind = Binary then
                        declare
                           Left_Cell  : Cell_Data renames P (Part, S_Idx, Prod.RHS_1);
                           Right_Cell : Cell_Data renames P (L - Part, S_Idx + Part, Prod.RHS_2);
                        begin
                           if Left_Cell.Valid and then Right_Cell.Valid and then not P (L, S_Idx, Prod.LHS).Valid then
                              P (L, S_Idx, Prod.LHS).Valid := True;
                              P (L, S_Idx, Prod.LHS).Node := new Parse_Node'
                                (Kind   => Nonterminal_Node,
                                 Symbol => Prod.LHS,
                                 Left   => new Parse_Node'(Left_Cell.Node.all),
                                 Right  => new Parse_Node'(Right_Cell.Node.all));
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;

      if P (N, 1, G.Start_Sym).Valid then
         return new Parse_Node'(P (N, 1, G.Start_Sym).Node.all);
      else
         return null;
      end if;
   end Parse;

   ----------------------------------------------------------------------------
   -- Parse_Weighted Implementation (Variant 3)
   ----------------------------------------------------------------------------
   procedure Parse_Weighted
     (G          : in     Weighted_Grammar;
      Input      : in     Input_String;
      Accepted   :    out Boolean;
      Best_Log_P :    out Log_Probability;
      Root       :    out Parse_Node_Access)
   is
      N : constant Natural := Input'Length;

      type Weighted_Cell is record
         Valid    : Boolean := False;
         Log_Prob : Log_Probability := -1.0E38;
         Node     : Parse_Node_Access := null;
      end record;

      type Table_Weighted is array (1 .. N, 1 .. N, Nonterminal) of Weighted_Cell;
      P : Table_Weighted := [others => [others => [others => (Valid => False, Log_Prob => -1.0E38, Node => null)]]];
   begin
      Accepted := False;
      Best_Log_P := -1.0E38;
      Root := null;

      -- 1. Base case: length 1
      for S_Idx in 1 .. N loop
         for P_Idx in 1 .. G.Count loop
            declare
               Prod : Weighted_Production renames G.Productions (P_Idx);
            begin
               if Prod.Kind = Terminal_Prod and then Prod.RHS_Terminal = Input (S_Idx) then
                  if not P (1, S_Idx, Prod.LHS).Valid or else Prod.Log_Prob > P (1, S_Idx, Prod.LHS).Log_Prob then
                     P (1, S_Idx, Prod.LHS).Valid := True;
                     P (1, S_Idx, Prod.LHS).Log_Prob := Prod.Log_Prob;
                     P (1, S_Idx, Prod.LHS).Node := new Parse_Node'(Kind   => Terminal_Node,
                                                                    Symbol => Prod.LHS,
                                                                    Term   => Input (S_Idx));
                  end if;
               end if;
            end;
         end loop;
      end loop;

      -- 2. Recursive steps: lengths 2 to N
      for L in 2 .. N loop
         for S_Idx in 1 .. N - L + 1 loop
            for Part in 1 .. L - 1 loop
               for P_Idx in 1 .. G.Count loop
                  declare
                     Prod : Weighted_Production renames G.Productions (P_Idx);
                  begin
                     if Prod.Kind = Binary then
                        declare
                           Left_Cell  : Weighted_Cell renames P (Part, S_Idx, Prod.RHS_1);
                           Right_Cell : Weighted_Cell renames P (L - Part, S_Idx + Part, Prod.RHS_2);
                        begin
                           if Left_Cell.Valid and then Right_Cell.Valid then
                              declare
                                 New_Log_P : constant Log_Probability := Prod.Log_Prob + Left_Cell.Log_Prob + Right_Cell.Log_Prob;
                              begin
                                 if not P (L, S_Idx, Prod.LHS).Valid or else New_Log_P > P (L, S_Idx, Prod.LHS).Log_Prob then
                                    P (L, S_Idx, Prod.LHS).Valid := True;
                                    P (L, S_Idx, Prod.LHS).Log_Prob := New_Log_P;
                                    P (L, S_Idx, Prod.LHS).Node := new Parse_Node'
                                      (Kind   => Nonterminal_Node,
                                       Symbol => Prod.LHS,
                                       Left   => new Parse_Node'(Left_Cell.Node.all),
                                       Right  => new Parse_Node'(Right_Cell.Node.all));
                                 end if;
                              end;
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;

      if P (N, 1, G.Start_Sym).Valid then
         Accepted := True;
         Best_Log_P := P (N, 1, G.Start_Sym).Log_Prob;
         Root := new Parse_Node'(P (N, 1, G.Start_Sym).Node.all);
      end if;
   end Parse_Weighted;

   ----------------------------------------------------------------------------
   -- Free_Parse_Tree Implementation
   ----------------------------------------------------------------------------
   procedure Free_Parse_Tree (Node : in out Parse_Node_Access) is
      procedure Deallocate is new Ada.Unchecked_Deallocation (Parse_Node, Parse_Node_Access);
   begin
      if Node /= null then
         if Node.Kind = Nonterminal_Node then
            Free_Parse_Tree (Node.Left);
            Free_Parse_Tree (Node.Right);
         end if;
         Deallocate (Node);
      end if;
   end Free_Parse_Tree;

   ----------------------------------------------------------------------------
   -- Tree_ToString Implementation
   ----------------------------------------------------------------------------
   function Tree_ToString (Node : Parse_Node_Access) return String is
   begin
      if Node = null then
         return "()";
      end if;
      
      case Node.Kind is
         when Terminal_Node =>
            return "(" & Node.Symbol & " -> " & Node.Term & ")";
         when Nonterminal_Node =>
            return "(" & Node.Symbol & " " & Tree_ToString (Node.Left) & " " & Tree_ToString (Node.Right) & ")";
      end case;
   end Tree_ToString;

end Cyk_Algorithm;
