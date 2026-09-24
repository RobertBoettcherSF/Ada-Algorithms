pragma Ada_2012;

package body Package_Merge is

   -- Variant 1: Coin Collector's Problem
   function Coin_Collector
     (Coins      : Coin_Array;
      Target_Sum : Natural) return Selected_Coins
   is
      Max_E : Natural := 0;
      
      type CC_Item_Kind is (Single, Pkg);
      type CC_Item (Kind : CC_Item_Kind := Single) is record
         Value : Weight_Type;
         case Kind is
            when Single =>
               Coin_Id : Positive;
            when Pkg =>
               Left, Right : Positive;
         end case;
      end record;
      
      -- Max nodes bounds to approx 2 * Initial Coins
      Max_Nodes : constant Positive := Coins'Length * 2 + 10;
      Items     : array (1 .. Max_Nodes) of CC_Item;
      Last_Item : Natural := 0;
      
      type Element_Array is array (1 .. Max_Nodes) of Positive;
      type CC_List_Type is record
         Count    : Natural := 0;
         Elements : Element_Array;
      end record;
   begin
      if Target_Sum = 0 then
         return Selected_Coins'(1 .. 0 => 1);
      end if;

      for C of Coins loop
         if C.Denomination_Exp > Max_E then 
            Max_E := C.Denomination_Exp; 
         end if;
      end loop;
      
      declare
         L : array (0 .. Max_E) of CC_List_Type;
      begin
         -- Populate and sort initial lists
         for I in Coins'Range loop
            Last_Item := Last_Item + 1;
            Items(Last_Item) := (Kind => Single, Value => Coins(I).Numismatic_Value, Coin_Id => Coins(I).Id);
            declare
               E : constant Natural := Coins(I).Denomination_Exp;
            begin
               L(E).Count := L(E).Count + 1;
               L(E).Elements(L(E).Count) := Last_Item;
            end;
         end loop;
         
         for E in 0 .. Max_E loop
            for I in 2 .. L(E).Count loop
               declare
                  Temp : constant Positive := L(E).Elements(I);
                  J : Integer := I - 1;
               begin
                  while J >= 1 and then Items(L(E).Elements(J)).Value > Items(Temp).Value loop
                     L(E).Elements(J + 1) := L(E).Elements(J);
                     J := J - 1;
                  end loop;
                  L(E).Elements(J + 1) := Temp;
               end;
            end loop;
         end loop;
         
         -- Package and Merge
         for E in reverse 1 .. Max_E loop
            declare
               Num_Pairs : constant Natural := L(E).Count / 2;
               Packages  : CC_List_Type;
               Next_L    : CC_List_Type;
               I, J      : Positive := 1;
            begin
               -- Package
               for Pair in 1 .. Num_Pairs loop
                  declare
                     Left_Idx  : constant Positive := L(E).Elements(Pair * 2 - 1);
                     Right_Idx : constant Positive := L(E).Elements(Pair * 2);
                     W         : constant Weight_Type := Items(Left_Idx).Value + Items(Right_Idx).Value;
                  begin
                     Last_Item := Last_Item + 1;
                     Items(Last_Item) := (Kind => Pkg, Value => W, Left => Left_Idx, Right => Right_Idx);
                     Packages.Count := Packages.Count + 1;
                     Packages.Elements(Packages.Count) := Last_Item;
                  end;
               end loop;
               
               -- Merge with L(E-1)
               while I <= Packages.Count and J <= L(E-1).Count loop
                  if Items(Packages.Elements(I)).Value <= Items(L(E-1).Elements(J)).Value then
                     Next_L.Count := Next_L.Count + 1;
                     Next_L.Elements(Next_L.Count) := Packages.Elements(I);
                     I := I + 1;
                  else
                     Next_L.Count := Next_L.Count + 1;
                     Next_L.Elements(Next_L.Count) := L(E-1).Elements(J);
                     J := J + 1;
                  end if;
               end loop;
               while I <= Packages.Count loop
                  Next_L.Count := Next_L.Count + 1;
                  Next_L.Elements(Next_L.Count) := Packages.Elements(I);
                  I := I + 1;
               end loop;
               while J <= L(E-1).Count loop
                  Next_L.Count := Next_L.Count + 1;
                  Next_L.Elements(Next_L.Count) := L(E-1).Elements(J);
                  J := J + 1;
               end loop;
               
               L(E-1) := Next_L;
            end;
         end loop;
         
         if L(0).Count < Target_Sum then
            raise Invalid_Target with "Not enough coins to reach target sum";
         end if;
         
         -- Trace back
         declare
            Result       : Selected_Coins(1 .. Coins'Length);
            Result_Count : Natural := 0;
            
            procedure Collect(Idx : Positive) is
            begin
               if Items(Idx).Kind = Single then
                  Result_Count := Result_Count + 1;
                  Result(Result_Count) := Items(Idx).Coin_Id;
               else
                  Collect(Items(Idx).Left);
                  Collect(Items(Idx).Right);
               end if;
            end Collect;
         begin
            for I in 1 .. Target_Sum loop
               Collect(L(0).Elements(I));
            end loop;
            return Result(1 .. Result_Count);
         end;
      end;
   end Coin_Collector;

   -- Variant 2: Reduction of Huffman to Coin Collector
   function Huffman_Via_Coin_Collector
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths
   is
      N : constant Natural := Frequencies'Length;
   begin
      if N < 2 then return Code_Lengths'(Frequencies'Range => 1); end if;
      if N > 2**Max_Length then raise Invalid_Frequencies with "Code length too short"; end if;
      
      declare
         Total_Coins : constant Natural := N * Max_Length;
         Coins       : Coin_Array(1 .. Total_Coins);
         Idx         : Natural := 0;
      begin
         for Sym in Frequencies'Range loop
            for Exp in 1 .. Max_Length loop
               Idx := Idx + 1;
               Coins(Idx) := (Id => Idx, Symbol => Sym, Numismatic_Value => Frequencies(Sym), Denomination_Exp => Exp);
            end loop;
         end loop;
         
         declare
            Target   : constant Natural := N - 1;
            Selected : constant Selected_Coins := Coin_Collector(Coins, Target);
            Lengths  : Code_Lengths(Frequencies'Range) := (others => 0);
         begin
            for S of Selected loop
               Lengths(Coins(S).Symbol) := Lengths(Coins(S).Symbol) + 1;
            end loop;
            return Lengths;
         end;
      end;
   end Huffman_Via_Coin_Collector;

   -- Variant 3: Space-Efficient Length-Limited Huffman
   function Space_Efficient_Huffman
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths
   is
      N : constant Natural := Frequencies'Length;
   begin
      if N < 2 then return Code_Lengths'(Frequencies'Range => 1); end if;
      if N > 2**Max_Length then raise Invalid_Frequencies with "Code length too short"; end if;
      
      declare
         Max_Keep  : constant Natural := 2 * N - 2; -- Active pruning threshold
         Max_Nodes : constant Positive := N * Max_Length * 2;
         
         type Node_Kind is (Leaf, Pkg);
         type Node_Record (Kind : Node_Kind := Leaf) is record
            Weight : Weight_Type;
            case Kind is
               when Leaf => Sym : Symbol_Index;
               when Pkg => Left, Right : Positive;
            end case;
         end record;
         
         Nodes     : array (1 .. Max_Nodes) of Node_Record;
         Last_Node : Natural := 0;
         
         type Element_Array is array (1 .. N * 3) of Positive;
         type List_Type is record
            Count    : Natural := 0;
            Elements : Element_Array;
         end record;
         
         L_0, L_Curr, Packages : List_Type;
      begin
         -- Initialization
         for Sym in Frequencies'Range loop
            Last_Node := Last_Node + 1;
            Nodes(Last_Node) := (Kind => Leaf, Weight => Frequencies(Sym), Sym => Sym);
            L_0.Count := L_0.Count + 1;
            L_0.Elements(L_0.Count) := Last_Node;
         end loop;
         
         for I in 2 .. L_0.Count loop
            declare
               Temp : constant Positive := L_0.Elements(I);
               J : Integer := I - 1;
            begin
               while J >= 1 and then Nodes(L_0.Elements(J)).Weight > Nodes(Temp).Weight loop
                  L_0.Elements(J + 1) := L_0.Elements(J);
                  J := J - 1;
               end loop;
               L_0.Elements(J + 1) := Temp;
            end;
         end loop;
         
         L_Curr := L_0;
         
         -- Merge phases
         for Step in 1 .. Max_Length - 1 loop
            Packages.Count := 0;
            declare
               Pairs : constant Natural := L_Curr.Count / 2;
            begin
               for I in 1 .. Pairs loop
                  declare
                     Left_Idx  : constant Positive := L_Curr.Elements(I * 2 - 1);
                     Right_Idx : constant Positive := L_Curr.Elements(I * 2);
                     W         : constant Weight_Type := Nodes(Left_Idx).Weight + Nodes(Right_Idx).Weight;
                  begin
                     Last_Node := Last_Node + 1;
                     Nodes(Last_Node) := (Kind => Pkg, Weight => W, Left => Left_Idx, Right => Right_Idx);
                     Packages.Count := Packages.Count + 1;
                     Packages.Elements(Packages.Count) := Last_Node;
                  end;
               end loop;
            end;
            
            declare
               Next_L : List_Type;
               I, J   : Positive := 1;
            begin
               while I <= Packages.Count and J <= L_0.Count loop
                  if Nodes(Packages.Elements(I)).Weight <= Nodes(L_0.Elements(J)).Weight then
                     Next_L.Count := Next_L.Count + 1;
                     Next_L.Elements(Next_L.Count) := Packages.Elements(I);
                     I := I + 1;
                  else
                     Next_L.Count := Next_L.Count + 1;
                     Next_L.Elements(Next_L.Count) := L_0.Elements(J);
                     J := J + 1;
                  end if;
               end loop;
               while I <= Packages.Count loop
                  Next_L.Count := Next_L.Count + 1;
                  Next_L.Elements(Next_L.Count) := Packages.Elements(I);
                  I := I + 1;
               end loop;
               while J <= L_0.Count loop
                  Next_L.Count := Next_L.Count + 1;
                  Next_L.Elements(Next_L.Count) := L_0.Elements(J);
                  J := J + 1;
               end loop;
               
               -- Space-efficiency pruning: discard items outside 2N-2
               if Next_L.Count > Max_Keep then
                  Next_L.Count := Max_Keep;
               end if;
               L_Curr := Next_L;
            end;
         end loop;
         
         declare
            Lengths : Code_Lengths(Frequencies'Range) := (others => 0);
            procedure Traverse (Idx : Positive) is
            begin
               if Nodes(Idx).Kind = Leaf then
                  Lengths(Nodes(Idx).Sym) := Lengths(Nodes(Idx).Sym) + 1;
               else
                  Traverse(Nodes(Idx).Left);
                  Traverse(Nodes(Idx).Right);
               end if;
            end Traverse;
         begin
            for I in 1 .. Integer'Min(Max_Keep, L_Curr.Count) loop
               Traverse (L_Curr.Elements(I));
            end loop;
            return Lengths;
         end;
      end;
   end Space_Efficient_Huffman;

   -- Variant 4: Alphabetic Length-Limited Coding
   function Alphabetic_Length_Limited
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths
   is
      N : constant Natural := Frequencies'Length;
   begin
      if N < 2 then return Code_Lengths'(Frequencies'Range => 1); end if;
      if N > 2**Max_Length then raise Invalid_Frequencies with "Code length too short"; end if;
      
      declare
         type Cost_Array is array (1 .. N, 1 .. N, 0 .. Max_Length) of Weight_Type;
         type Split_Array is array (1 .. N, 1 .. N, 0 .. Max_Length) of Natural;
         C : Cost_Array := (others => (others => (others => Weight_Type'Last / 2.0)));
         S : Split_Array := (others => (others => (others => 0)));
         Sum : array (1 .. N, 1 .. N) of Weight_Type;
         Lengths : Code_Lengths (Frequencies'Range) := (others => 0);
      begin
         for I in 1 .. N loop
            for J in I .. N loop
               declare
                  Total : Weight_Type := 0.0;
               begin
                  for K in I .. J loop Total := Total + Frequencies(Symbol_Index(K)); end loop;
                  Sum (I, J) := Total;
               end;
            end loop;
         end loop;
         
         for I in 1 .. N loop
            for L in 0 .. Max_Length loop
               C (I, I, L) := 0.0;
            end loop;
         end loop;
         
         for Len in 2 .. N loop
            for I in 1 .. N - Len + 1 loop
               declare
                  J : constant Natural := I + Len - 1;
               begin
                  for L in 1 .. Max_Length loop
                     for K in I .. J - 1 loop
                        declare
                           Cost : Weight_Type := C(I, K, L - 1) + C(K + 1, J, L - 1) + Sum(I, J);
                        begin
                           if Cost < C(I, J, L) then
                              C(I, J, L) := Cost;
                              S(I, J, L) := K;
                           end if;
                        end;
                     end loop;
                  end loop;
               end;
            end loop;
         end loop;
         
         if C(1, N, Max_Length) >= Weight_Type'Last / 2.0 then
            raise Invalid_Frequencies with "Cannot form alphabetic tree";
         end if;
         
         declare
            procedure Assign_Lengths (I, J : Natural; L : Natural; Depth : Natural) is
            begin
               if I = J then
                  Lengths (Symbol_Index(I)) := Depth;
               else
                  declare
                     K : constant Natural := S(I, J, L);
                  begin
                     Assign_Lengths (I, K, L - 1, Depth + 1);
                     Assign_Lengths (K + 1, J, L - 1, Depth + 1);
                  end;
               end if;
            end Assign_Lengths;
         begin
            Assign_Lengths(1, N, Max_Length, 0);
            return Lengths;
         end;
      end;
   end Alphabetic_Length_Limited;

end Package_Merge;
