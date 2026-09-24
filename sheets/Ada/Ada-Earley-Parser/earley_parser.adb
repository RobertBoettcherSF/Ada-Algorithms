package body Earley_Parser is

   ---------
   -- "=" --
   ---------
   function "=" (Left, Right : Symbol) return Boolean is
   begin
      return Left.Kind = Right.Kind and then Left.Name = Right.Name;
   end "=";

   function "=" (Left, Right : Item) return Boolean is
   begin
      return Left.Rule_Index = Right.Rule_Index and then
             Left.Dot = Right.Dot and then
             Left.Origin = Right.Origin;
   end "=";

   ---------------------
   -- Create_Terminal --
   ---------------------
   function Create_Terminal (Name : String) return Symbol is
   begin
      return (Kind => Terminal, Name => To_Unbounded_String (Name));
   end Create_Terminal;

   -------------------------
   -- Create_Non_Terminal --
   -------------------------
   function Create_Non_Terminal (Name : String) return Symbol is
   begin
      return (Kind => Non_Terminal, Name => To_Unbounded_String (Name));
   end Create_Non_Terminal;

   --------------
   -- Add_Item --
   --------------
   --  Safely adds an Item to a specific Chart set without raising 
   --  Tampering_With_Cursors during vector iteration.
   procedure Add_Item (C : in out Chart; Set_Index : Natural; Itm : Item) is
      Set : Item_List := C.Element (Set_Index);
   begin
      if not Set.Contains (Itm) then
         Set.Append (Itm);
         C.Replace_Element (Set_Index, Set);
      end if;
   end Add_Item;

   -------------
   -- Predict --
   -------------
   --  For every state of the form (X -> alpha . Y beta, j),
   --  add (Y -> . gamma, k) to S(k) for every production Y -> gamma.
   procedure Predict
     (G        : Grammar;
      C        : in out Chart;
      K        : Natural;
      Non_Term : Symbol)
   is
   begin
      for I in 1 .. Natural (G.Rules.Length) loop
         if G.Rules.Element (I).LHS = Non_Term then
            Add_Item (C, K, (Rule_Index => I, Dot => 0, Origin => K));
         end if;
      end loop;
   end Predict;

   ----------
   -- Scan --
   ----------
   --  If the next input token matches the expected terminal,
   --  advance the dot and add to the next state set.
   procedure Scan (C : in out Chart; K : Natural; State : Item) is
   begin
      Add_Item (C, K + 1, (Rule_Index => State.Rule_Index,
                           Dot        => State.Dot + 1,
                           Origin     => State.Origin));
   end Scan;

   --------------
   -- Complete --
   --------------
   --  For every completed state (Y -> gamma ., j) in S(k),
   --  find states in S(j) of the form (X -> alpha . Y beta, i)
   --  and add (X -> alpha Y . beta, i) to S(k).
   procedure Complete
     (G     : Grammar;
      C     : in out Chart;
      K     : Natural;
      State : Item)
   is
      Origin_Set : constant Item_List := C.Element (State.Origin);
      Prod       : constant Production := G.Rules.Element (State.Rule_Index);
      LHS_Sym    : constant Symbol := Prod.LHS;
   begin
      for I in 1 .. Natural (Origin_Set.Length) loop
         declare
            Origin_Item : constant Item := Origin_Set.Element (I);
            Orig_Prod   : constant Production := G.Rules.Element (Origin_Item.Rule_Index);
         begin
            if Origin_Item.Dot < Natural (Orig_Prod.RHS.Length) then
               if Orig_Prod.RHS.Element (Origin_Item.Dot + 1) = LHS_Sym then
                  Add_Item (C, K, (Rule_Index => Origin_Item.Rule_Index,
                                   Dot        => Origin_Item.Dot + 1,
                                   Origin     => Origin_Item.Origin));
               end if;
            end if;
         end;
      end loop;
   end Complete;

   -----------------
   -- Parse_Chart --
   -----------------
   function Parse_Chart (G : Grammar; Input : Symbol_List) return Chart is
      N : constant Natural := Natural (Input.Length);
      C : Chart;
   begin
      --  Initialize the Chart with empty sets from 0 to N
      for I in 0 .. N loop
         C.Append (Item_Vectors.Empty_Vector);
      end loop;

      --  Initialize S(0) with rules matching the Start_Symbol
      for I in 1 .. Natural (G.Rules.Length) loop
         if G.Rules.Element (I).LHS = G.Start_Symbol then
            Add_Item (C, 0, (Rule_Index => I, Dot => 0, Origin => 0));
         end if;
      end loop;

      --  Process all state sets
      for K in 0 .. N loop
         declare
            J : Positive := 1;
         begin
            --  Use an index loop because Add_Item modifies the Vector, 
            --  which would invalidate standard cursors.
            while J <= Natural (C.Element (K).Length) loop
               declare
                  State : constant Item := C.Element (K).Element (J);
                  Prod  : constant Production := G.Rules.Element (State.Rule_Index);
               begin
                  if State.Dot < Natural (Prod.RHS.Length) then
                     declare
                        Next_Symbol : constant Symbol := Prod.RHS.Element (State.Dot + 1);
                     begin
                        if Next_Symbol.Kind = Non_Terminal then
                           --  Prediction step
                           Predict (G, C, K, Next_Symbol);
                        else
                           --  Scanning step
                           if K < N then
                              if Next_Symbol = Input.Element (K + 1) then
                                 Scan (C, K, State);
                              end if;
                           end if;
                        end if;
                     end;
                  else
                     --  Completion step
                     Complete (G, C, K, State);
                  end if;
               end;
               J := J + 1;
            end loop;
         end;
      end loop;

      return C;
   end Parse_Chart;

   ---------------
   -- Recognize --
   ---------------
   function Recognize (G : Grammar; Input : Symbol_List) return Boolean is
      N         : constant Natural := Natural (Input.Length);
      C         : constant Chart := Parse_Chart (G, Input);
      Final_Set : constant Item_List := C.Element (N);
   begin
      --  Check if the final state set contains a completed Start_Symbol rule
      --  that spans from Origin 0 to N.
      for I in 1 .. Natural (Final_Set.Length) loop
         declare
            Itm : constant Item := Final_Set.Element (I);
            Prd : constant Production := G.Rules.Element (Itm.Rule_Index);
         begin
            if Prd.LHS = G.Start_Symbol and then
               Itm.Dot = Natural (Prd.RHS.Length) and then
               Itm.Origin = 0
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Recognize;

end Earley_Parser;
