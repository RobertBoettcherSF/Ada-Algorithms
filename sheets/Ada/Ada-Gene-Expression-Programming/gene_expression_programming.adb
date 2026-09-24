--  Gene_Expression_Programming body — Ferreira educational GEP.

pragma Ada_2022;

package body Gene_Expression_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Near / config
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Pop_Size       : Pop_Size_T    := 20;
      Generations    : Natural       := 40;
      Head           : Head_Len      := 3;
      Crossover_Rate : Unit_Interval := 0.7;
      Mutation_Rate  : Unit_Interval := 0.1;
      Tournament_K   : Tourney_K     := 3;
      Elite_Count    : Elite_T       := 1;
      Seed           : Natural       := 1;
      Use_Ephemeral  : Boolean       := False) return Config
   is
   begin
      return
        (Pop_Size       => Pop_Size,
         Generations    => Generations,
         Head           => Head,
         Crossover_Rate => Crossover_Rate,
         Mutation_Rate  => Mutation_Rate,
         Tournament_K   => Tournament_K,
         Elite_Count    => Elite_Count,
         Seed           => Seed,
         Use_Ephemeral  => Use_Ephemeral);
   end Default_Config;

   function Config_Is_Valid (Cfg : Config) return Boolean is
   begin
      return Cfg.Tournament_K <= Cfg.Pop_Size
        and then Cfg.Elite_Count < Cfg.Pop_Size;
   end Config_Is_Valid;

   ---------------------------------------------------------------------------
   -- LCG RNG (Numerical Recipes style)
   ---------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      U    : constant Unit_Interval := Next_Unit (State);
      Span : constant Natural := Hi - Lo;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + (Hi - Lo) * Real (U);
   end Next_Real;

   ---------------------------------------------------------------------------
   -- Symbol helpers
   ---------------------------------------------------------------------------

   function Is_Function (S : Symbol) return Boolean is
   begin
      return S = '+' or else S = '-' or else S = '*' or else S = '/';
   end Is_Function;

   function Is_Terminal (S : Symbol) return Boolean is
   begin
      return S = 'a' or else S = 'b' or else S = '?';
   end Is_Terminal;

   function Arity_Of (S : Symbol) return Natural is
   begin
      if Is_Function (S) then
         return 2;
      else
         return 0;
      end if;
   end Arity_Of;

   function Tail_Length (H : Head_Len; N_Max : Positive := Max_Nmax)
     return Positive
   is
   begin
      return H * (N_Max - 1) + 1;
   end Tail_Length;

   function Gene_Length_Of (H : Head_Len; N_Max : Positive := Max_Nmax)
     return Gene_Len
   is
   begin
      return Gene_Len (H + Tail_Length (H, N_Max));
   end Gene_Length_Of;

   function Gene_Is_Well_Formed (G : Gene) return Boolean is
      Expected : constant Gene_Len := Gene_Length_Of (G.Head);
   begin
      if G.Length /= Expected then
         return False;
      end if;
      for I in 1 .. G.Head loop
         if not (Is_Function (G.Symbols (I))
           or else Is_Terminal (G.Symbols (I)))
         then
            return False;
         end if;
      end loop;
      for I in G.Head + 1 .. G.Length loop
         if not Is_Terminal (G.Symbols (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Gene_Is_Well_Formed;

   ---------------------------------------------------------------------------
   -- Random symbols
   ---------------------------------------------------------------------------

   function Random_Function (State : in out RNG_State) return Symbol is
      K : constant Natural := Next_Natural (State, 0, 3);
   begin
      case K is
         when 0 => return '+';
         when 1 => return '-';
         when 2 => return '*';
         when others => return '/';
      end case;
   end Random_Function;

   function Random_Terminal
     (State : in out RNG_State; Use_Ephemeral : Boolean) return Symbol
   is
      K : Natural;
   begin
      if Use_Ephemeral then
         K := Next_Natural (State, 0, 2);
         case K is
            when 0 => return 'a';
            when 1 => return 'b';
            when others => return '?';
         end case;
      else
         K := Next_Natural (State, 0, 1);
         if K = 0 then
            return 'a';
         else
            return 'b';
         end if;
      end if;
   end Random_Terminal;

   function Random_Head_Symbol
     (State : in out RNG_State; Use_Ephemeral : Boolean) return Symbol
   is
   begin
      --  ~50% function / ~50% terminal in the head
      if Next_Unit (State) < 0.5 then
         return Random_Function (State);
      else
         return Random_Terminal (State, Use_Ephemeral);
      end if;
   end Random_Head_Symbol;

   ---------------------------------------------------------------------------
   -- Construction
   ---------------------------------------------------------------------------

   function Make_Gene
     (Symbols   : Symbol_Array;
      Head      : Head_Len;
      Ephemeral : Real := 1.0) return Gene
   is
      G : Gene;
      L : constant Gene_Len := Gene_Length_Of (Head);
   begin
      if Symbols'Length /= Natural (L) then
         raise Invalid_Argument;
      end if;
      G.Head := Head;
      G.Length := L;
      G.Ephemeral := Ephemeral;
      for I in 1 .. L loop
         G.Symbols (I) := Symbols (Symbols'First + I - 1);
      end loop;
      if not Gene_Is_Well_Formed (G) then
         raise Invalid_Argument;
      end if;
      return G;
   end Make_Gene;

   function Random_Gene
     (State         : in out RNG_State;
      Head          : Head_Len;
      Use_Ephemeral : Boolean := False) return Gene
   is
      G : Gene;
      L : constant Gene_Len := Gene_Length_Of (Head);
   begin
      G.Head := Head;
      G.Length := L;
      if Use_Ephemeral then
         G.Ephemeral := Next_Real (State, -2.0, 2.0);
      else
         G.Ephemeral := 1.0;
      end if;
      for I in 1 .. Head loop
         G.Symbols (I) := Random_Head_Symbol (State, Use_Ephemeral);
      end loop;
      for I in Head + 1 .. L loop
         G.Symbols (I) := Random_Terminal (State, Use_Ephemeral);
      end loop;
      return G;
   end Random_Gene;

   ---------------------------------------------------------------------------
   -- Genetic operators
   ---------------------------------------------------------------------------

   procedure Mutate
     (G             : in out Gene;
      State         : in out RNG_State;
      Rate          : Unit_Interval;
      Use_Ephemeral : Boolean := False)
   is
   begin
      for I in 1 .. G.Length loop
         if Next_Unit (State) < Rate then
            if I <= G.Head then
               G.Symbols (I) := Random_Head_Symbol (State, Use_Ephemeral);
            else
               G.Symbols (I) := Random_Terminal (State, Use_Ephemeral);
            end if;
         end if;
      end loop;
      if Use_Ephemeral and then Next_Unit (State) < Rate then
         G.Ephemeral := Next_Real (State, -2.0, 2.0);
      end if;
   end Mutate;

   procedure Crossover_One_Point
     (A, B   : Gene;
      Child1 : out Gene;
      Child2 : out Gene;
      State  : in out RNG_State)
   is
      Cut : Natural;
   begin
      if A.Head /= B.Head or else A.Length /= B.Length then
         raise Invalid_Argument;
      end if;
      Child1 := A;
      Child2 := B;
      --  cut after position Cut (1 .. Length-1); always exchange suffix
      if A.Length = 1 then
         return;
      end if;
      Cut := Next_Natural (State, 1, Natural (A.Length) - 1);
      for I in Cut + 1 .. A.Length loop
         Child1.Symbols (I) := B.Symbols (I);
         Child2.Symbols (I) := A.Symbols (I);
      end loop;
      --  Blend ephemerals lightly
      Child1.Ephemeral := A.Ephemeral;
      Child2.Ephemeral := B.Ephemeral;
   end Crossover_One_Point;

   procedure Transpose_Stub
     (G     : in out Gene;
      State : in out RNG_State)
   is
      --  Copy a length-1 or length-2 subsequence within the head to another
      --  head index (overwrite). Educational IS transposition approximation.
      Src, Dst, Len : Natural;
      Tmp           : Symbol_Array (1 .. 2);
   begin
      if G.Head < 2 then
         return;
      end if;
      Len := Next_Natural (State, 1, 2);
      if Len > Natural (G.Head) then
         Len := Natural (G.Head);
      end if;
      Src := Next_Natural (State, 1, Natural (G.Head) - Len + 1);
      Dst := Next_Natural (State, 1, Natural (G.Head) - Len + 1);
      if Src = Dst then
         return;
      end if;
      for I in 0 .. Len - 1 loop
         Tmp (I + 1) := G.Symbols (Src + I);
      end loop;
      for I in 0 .. Len - 1 loop
         G.Symbols (Dst + I) := Tmp (I + 1);
      end loop;
   end Transpose_Stub;

   ---------------------------------------------------------------------------
   -- Protected division / ORF / evaluate
   ---------------------------------------------------------------------------

   function Protected_Divide (Num, Den : Real) return Real is
   begin
      if abs (Den) <= Protected_Div_Eps then
         return Num;
      else
         return Num / Den;
      end if;
   end Protected_Divide;

   function ORF_Length (G : Gene) return Natural is
      --  Level-order Karva scan: start with 1 node pending at root;
      --  each function consumes one pending slot and adds Arity children.
      Pending : Integer := 1;
      Used    : Natural := 0;
   begin
      for I in 1 .. G.Length loop
         exit when Pending <= 0;
         Used := Used + 1;
         Pending := Pending - 1;
         Pending := Pending + Integer (Arity_Of (G.Symbols (I)));
      end loop;
      return Used;
   end ORF_Length;

   function Evaluate
     (G : Gene; A, B : Real) return Real
   is
      --  Build values bottom-up matching Karva level-order:
      --  collect ORF symbols, then evaluate with a post-order stack by
      --  walking the ORF from the end (children before parents in reverse
      --  breadth-order requires care). Simpler: recursive decode from index.
      ORF : constant Natural := ORF_Length (G);

      function Terminal_Value (S : Symbol) return Real is
      begin
         case S is
            when 'a' => return A;
            when 'b' => return B;
            when '?' => return G.Ephemeral;
            when others => return 0.0;
         end case;
      end Terminal_Value;

      --  Recursive evaluation starting at position Pos in the gene.
      --  Next_Free tracks the next unused symbol index (Karva queue).
      procedure Eval_From
        (Pos       : Positive;
         Next_Free : in out Positive;
         Value     : out Real)
      is
         S  : constant Symbol := G.Symbols (Pos);
         V1 : Real;
         V2 : Real;
         C1 : Positive;
         C2 : Positive;
      begin
         if not Is_Function (S) then
            Value := Terminal_Value (S);
            return;
         end if;
         --  Children occupy the next two free slots in level order.
         C1 := Next_Free;
         Next_Free := Next_Free + 1;
         C2 := Next_Free;
         Next_Free := Next_Free + 1;
         Eval_From (C1, Next_Free, V1);
         Eval_From (C2, Next_Free, V2);
         case S is
            when '+' => Value := V1 + V2;
            when '-' => Value := V1 - V2;
            when '*' => Value := V1 * V2;
            when '/' => Value := Protected_Divide (V1, V2);
            when others => Value := 0.0;
         end case;
      end Eval_From;

      Next_Free : Positive := 2;
      Value     : Real;
   begin
      if ORF = 0 then
         return 0.0;
      end if;
      if ORF = 1 then
         return Terminal_Value (G.Symbols (1));
      end if;
      Eval_From (1, Next_Free, Value);
      return Value;
   end Evaluate;

   function MSE
     (G : Gene; Data : Sample_Array) return Non_Negative
   is
      Sum : Real := 0.0;
      Pred, Diff : Real;
      N : constant Real := Real (Data'Length);
   begin
      for S of Data loop
         Pred := Evaluate (G, S.A, S.B);
         Diff := Pred - S.Target;
         Sum := Sum + Diff * Diff;
      end loop;
      if N <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Sum / N);
   end MSE;

   function Fitness_From_MSE (Err : Real) return Non_Negative is
   begin
      if Err < 0.0 then
         return Non_Negative (1.0 / (1.0 + abs (Err)));
      end if;
      return Non_Negative (1.0 / (1.0 + Err));
   end Fitness_From_MSE;

   function Fitness_Of
     (G : Gene; Data : Sample_Array) return Non_Negative
   is
   begin
      return Fitness_From_MSE (MSE (G, Data));
   end Fitness_Of;

   ---------------------------------------------------------------------------
   -- Toy data
   ---------------------------------------------------------------------------

   function Make_Toy_Data
     (Kind  : Target_Kind;
      Count : Sample_Count;
      State : in out RNG_State;
      Lo    : Real := -2.0;
      Hi    : Real := 2.0) return Sample_Array
   is
      Data : Sample_Array (1 .. Count);
      AA, BB : Real;
   begin
      for I in Data'Range loop
         AA := Next_Real (State, Lo, Hi);
         BB := Next_Real (State, Lo, Hi);
         Data (I).A := AA;
         Data (I).B := BB;
         case Kind is
            when Sum_AB     => Data (I).Target := AA + BB;
            when Product_AB => Data (I).Target := AA * BB;
            when Diff_AB    => Data (I).Target := AA - BB;
         end case;
      end loop;
      return Data;
   end Make_Toy_Data;

   ---------------------------------------------------------------------------
   -- Selection / evolution
   ---------------------------------------------------------------------------

   function Tournament_Select
     (Fits  : Fitness_Array;
      K     : Tourney_K;
      State : in out RNG_State) return Positive
   is
      Best_I : Positive :=
        Next_Natural (State, Fits'First, Fits'Last);
      Cand   : Positive;
   begin
      for J in 2 .. K loop
         Cand := Next_Natural (State, Fits'First, Fits'Last);
         if Fits (Cand) > Fits (Best_I) then
            Best_I := Cand;
         end if;
      end loop;
      return Best_I;
   end Tournament_Select;

   function Evolve
     (Data : Sample_Array;
      Cfg  : Config) return Result
   is
      Pop_N : constant Pop_Size_T := Cfg.Pop_Size;
      Pop   : Gene_Array (1 .. Pop_N);
      NextP : Gene_Array (1 .. Pop_N);
      Fits  : Fitness_Array (1 .. Pop_N);
      State : RNG_State;
      R     : Result;
      Best_I : Positive := 1;
      I1, I2 : Positive;
      C1, C2 : Gene;
      Elite_Idx : array (1 .. Max_Pop) of Positive := [others => 1];

      procedure Rank_Elites is
         Used : array (1 .. Max_Pop) of Boolean := [others => False];
         Best_Local : Positive;
         Best_F : Real;
      begin
         for E in 1 .. Cfg.Elite_Count loop
            Best_Local := 1;
            Best_F := Real'First;
            for I in 1 .. Pop_N loop
               if not Used (I) and then Fits (I) > Best_F then
                  Best_F := Fits (I);
                  Best_Local := I;
               end if;
            end loop;
            Elite_Idx (E) := Best_Local;
            Used (Best_Local) := True;
         end loop;
      end Rank_Elites;

   begin
      if not Config_Is_Valid (Cfg) or else Data'Length < 1 then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for I in 1 .. Pop_N loop
         Pop (I) := Random_Gene (State, Cfg.Head, Cfg.Use_Ephemeral);
         Fits (I) := Fitness_Of (Pop (I), Data);
         R.Evaluations := R.Evaluations + 1;
      end loop;

      Best_I := 1;
      for I in 2 .. Pop_N loop
         if Fits (I) > Fits (Best_I) then
            Best_I := I;
         end if;
      end loop;
      R.Best := Pop (Best_I);
      R.Best_Fitness := Fits (Best_I);
      R.Best_MSE := MSE (R.Best, Data);

      if Cfg.Generations = 0 then
         R.Generations_Run := 0;
         R.History_Length := 0;
         return R;
      end if;

      for Gen in 1 .. Cfg.Generations loop
         Rank_Elites;
         --  Place elites
         for E in 1 .. Cfg.Elite_Count loop
            NextP (E) := Pop (Elite_Idx (E));
         end loop;

         declare
            Slot : Positive := Cfg.Elite_Count + 1;
         begin
            while Slot <= Pop_N loop
               I1 := Tournament_Select (Fits, Cfg.Tournament_K, State);
               I2 := Tournament_Select (Fits, Cfg.Tournament_K, State);
               if Next_Unit (State) < Cfg.Crossover_Rate then
                  Crossover_One_Point (Pop (I1), Pop (I2), C1, C2, State);
               else
                  C1 := Pop (I1);
                  C2 := Pop (I2);
               end if;
               Mutate (C1, State, Cfg.Mutation_Rate, Cfg.Use_Ephemeral);
               Mutate (C2, State, Cfg.Mutation_Rate, Cfg.Use_Ephemeral);
               --  Rare transposition stub
               if Next_Unit (State) < 0.05 then
                  Transpose_Stub (C1, State);
               end if;
               NextP (Slot) := C1;
               Slot := Slot + 1;
               if Slot <= Pop_N then
                  NextP (Slot) := C2;
                  Slot := Slot + 1;
               end if;
            end loop;
         end;

         Pop := NextP;
         for I in 1 .. Pop_N loop
            Fits (I) := Fitness_Of (Pop (I), Data);
            R.Evaluations := R.Evaluations + 1;
         end loop;

         Best_I := 1;
         for I in 2 .. Pop_N loop
            if Fits (I) > Fits (Best_I) then
               Best_I := I;
            end if;
         end loop;
         if Fits (Best_I) > R.Best_Fitness then
            R.Best := Pop (Best_I);
            R.Best_Fitness := Fits (Best_I);
            R.Best_MSE := MSE (R.Best, Data);
         end if;

         R.Generations_Run := Gen;
         R.History_Length := Gen;
      end loop;

      return R;
   end Evolve;

   function Fit_Symbolic
     (Kind : Target_Kind;
      Cfg  : Config) return Result
   is
      State : RNG_State;
      Data  : Sample_Array (1 .. 12);
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      Seed_RNG (State, Cfg.Seed + 99);
      Data := Make_Toy_Data (Kind, 12, State, -1.5, 1.5);
      return Evolve (Data, Cfg);
   end Fit_Symbolic;

end Gene_Expression_Programming;
