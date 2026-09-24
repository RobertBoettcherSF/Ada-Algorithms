--  Tests for Gene_Expression_Programming (educational Ferreira GEP).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Gene_Expression_Programming; use Gene_Expression_Programming;

procedure Tests is

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   procedure Check_Near
     (A, B : Real; Name : String; Tol : Real := 1.0E-8)
   is
   begin
      Check (Near (A, B, Tol), Name);
   end Check_Near;

   function Sym (S : String) return Symbol_Array is
      R : Symbol_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := S (I);
      end loop;
      return R;
   end Sym;

   State : RNG_State;
   G, G2, C1, C2 : Gene;
   Data : Sample_Array (1 .. 8);
   R : Result;
   F0, F1 : Real;
   L : Natural;
   V : Real;

begin
   ---------------------------------------------------------------------------
   -- Near / config
   ---------------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tight");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (0.0, 0.0), "Near zeros");
   Check (Config_Is_Valid (Default_Config), "Default config valid");
   Check
     (not Config_Is_Valid
        (Default_Config (Tournament_K => 40, Pop_Size => 20)),
      "Invalid tourney > pop");
   Check
     (not Config_Is_Valid
        (Default_Config (Elite_Count => 20, Pop_Size => 20)),
      "Invalid elite = pop");
   declare
      C : constant Config :=
        Default_Config
          (Pop_Size => 10, Generations => 5, Head => 2, Seed => 7);
   begin
      Check (C.Pop_Size = 10, "Default_Config pop");
      Check (C.Head = 2, "Default_Config head");
      Check (C.Seed = 7, "Default_Config seed");
      Check (Config_Is_Valid (C), "custom config valid");
   end;

   ---------------------------------------------------------------------------
   -- Length rule t = h*(n_max-1)+1  (nmax=2 => t=h+1, g=2h+1)
   ---------------------------------------------------------------------------
   Check (Tail_Length (1) = 2, "tail h=1");
   Check (Tail_Length (2) = 3, "tail h=2");
   Check (Tail_Length (3) = 4, "tail h=3");
   Check (Tail_Length (4) = 5, "tail h=4");
   Check (Tail_Length (5) = 6, "tail h=5");
   Check (Tail_Length (6) = 7, "tail h=6");
   Check (Gene_Length_Of (1) = 3, "glen h=1");
   Check (Gene_Length_Of (2) = 5, "glen h=2");
   Check (Gene_Length_Of (3) = 7, "glen h=3");
   Check (Gene_Length_Of (4) = 9, "glen h=4");
   Check (Gene_Length_Of (5) = 11, "glen h=5");
   Check (Gene_Length_Of (6) = 13, "glen h=6");
   declare
      H : Head_Len := 3;
      L : Gene_Len;
   begin
      L := Gene_Length_Of (H);
      Check (Natural (L) = Natural (H) + Tail_Length (H), "glen = h+t");
      H := 6;
      L := Gene_Length_Of (H);
      Check (Natural (L) = 13, "glen h=6 via var");
   end;

   ---------------------------------------------------------------------------
   -- Symbol helpers
   ---------------------------------------------------------------------------
   Check (Is_Function ('+'), "Is_Function +");
   Check (Is_Function ('-'), "Is_Function -");
   Check (Is_Function ('*'), "Is_Function *");
   Check (Is_Function ('/'), "Is_Function /");
   Check (not Is_Function ('a'), "not Is_Function a");
   Check (not Is_Function ('x'), "not Is_Function x");
   Check (Is_Terminal ('a'), "Is_Terminal a");
   Check (Is_Terminal ('b'), "Is_Terminal b");
   Check (Is_Terminal ('?'), "Is_Terminal ?");
   Check (not Is_Terminal ('+'), "not Is_Terminal +");
   Check (Arity_Of ('+') = 2, "Arity +");
   Check (Arity_Of ('*') = 2, "Arity *");
   Check (Arity_Of ('a') = 0, "Arity a");
   Check (Arity_Of ('?') = 0, "Arity ?");

   ---------------------------------------------------------------------------
   -- Protected division
   ---------------------------------------------------------------------------
   Check_Near (Protected_Divide (6.0, 2.0), 3.0, "pdiv 6/2");
   Check_Near (Protected_Divide (5.0, 0.0), 5.0, "pdiv 5/0");
   Check_Near (Protected_Divide (-3.0, 0.0), -3.0, "pdiv -3/0");
   Check_Near
     (Protected_Divide (1.0, Protected_Div_Eps / 10.0), 1.0, "pdiv tiny den");
   Check_Near (Protected_Divide (0.0, 0.0), 0.0, "pdiv 0/0");
   Check_Near (Protected_Divide (9.0, 3.0), 3.0, "pdiv 9/3");

   ---------------------------------------------------------------------------
   -- Handcrafted genes / decode / evaluate
   ---------------------------------------------------------------------------
   --  "+ababab" h=3,g=7 → ORF "+ab" = a+b
   G := Make_Gene (Sym ("+ababab"), 3);
   Check (Gene_Is_Well_Formed (G), "well formed +ab");
   Check (ORF_Length (G) = 3, "ORF +ab len");
   Check_Near (Evaluate (G, 2.0, 3.0), 5.0, "eval a+b");
   Check_Near (Evaluate (G, -1.0, 4.0), 3.0, "eval a+b neg");
   Check_Near (Evaluate (G, 0.0, 0.0), 0.0, "eval a+b zero");

   G := Make_Gene (Sym ("*ababab"), 3);
   Check_Near (Evaluate (G, 2.0, 3.0), 6.0, "eval a*b");
   Check_Near (Evaluate (G, -2.0, 0.5), -1.0, "eval a*b frac");

   G := Make_Gene (Sym ("-ababab"), 3);
   Check_Near (Evaluate (G, 5.0, 2.0), 3.0, "eval a-b");
   Check_Near (Evaluate (G, 1.0, 1.0), 0.0, "eval a-b zero");

   G := Make_Gene (Sym ("/ababab"), 3);
   Check_Near (Evaluate (G, 8.0, 2.0), 4.0, "eval a/b");
   Check_Near (Evaluate (G, 8.0, 0.0), 8.0, "eval a/0 protected");

   G := Make_Gene (Sym ("abb"), 1);
   Check (ORF_Length (G) = 1, "ORF terminal a");
   Check_Near (Evaluate (G, 7.0, 9.0), 7.0, "eval just a");

   G := Make_Gene (Sym ("baa"), 1);
   Check_Near (Evaluate (G, 7.0, 9.0), 9.0, "eval just b");

   --  "*+-abab" → (a+b)*(a-b)
   G := Make_Gene (Sym ("*+-abab"), 3);
   Check (ORF_Length (G) = 7, "ORF nested full");
   Check_Near (Evaluate (G, 4.0, 1.0), 15.0, "eval (a+b)*(a-b)");
   Check_Near (Evaluate (G, 3.0, 2.0), 5.0, "eval (a+b)*(a-b) 3,2");

   --  "+*ababa" → (a*b)+a
   G := Make_Gene (Sym ("+*ababa"), 3);
   Check_Near (Evaluate (G, 3.0, 4.0), 15.0, "eval (a*b)+a");

   G := Make_Gene (Sym ("?aa"), 1, Ephemeral => 2.5);
   Check_Near (Evaluate (G, 0.0, 0.0), 2.5, "eval ephemeral");

   G := Make_Gene (Sym ("+?aabab"), 3, Ephemeral => 10.0);
   Check_Near (Evaluate (G, 1.0, 0.0), 11.0, "eval ?+a");

   G := Make_Gene (Sym ("/baabab"), 3);
   Check_Near (Evaluate (G, 2.0, 10.0), 5.0, "eval b/a");

   --  h=2,g=5: "+*aba" → (b*a)+a
   G := Make_Gene (Sym ("+*aba"), 2);
   Check_Near (Evaluate (G, 3.0, 4.0), 15.0, "eval h=2 (b*a)+a");

   ---------------------------------------------------------------------------
   -- MSE / fitness
   ---------------------------------------------------------------------------
   declare
      D : Sample_Array (1 .. 3);
   begin
      G := Make_Gene (Sym ("+ababab"), 3);
      D :=
        [(A => 1.0, B => 2.0, Target => 3.0),
         (A => 0.0, B => 5.0, Target => 5.0),
         (A => -1.0, B => 1.0, Target => 0.0)];
      Check_Near (MSE (G, D), 0.0, "MSE perfect a+b");
      Check_Near (Fitness_Of (G, D), 1.0, "fitness perfect");
   end;

   declare
      D : Sample_Array (1 .. 2);
   begin
      G := Make_Gene (Sym ("*ababab"), 3);
      D :=
        [(A => 1.0, B => 1.0, Target => 0.0),
         (A => 2.0, B => 2.0, Target => 0.0)];
      Check_Near (MSE (G, D), 8.5, "MSE nonzero");
      Check
        (Fitness_Of (G, D) < 1.0 and then Fitness_Of (G, D) > 0.0,
         "fitness in (0,1)");
      Check_Near
        (Fitness_From_MSE (8.5), 1.0 / (1.0 + 8.5), "Fitness_From_MSE");
      Check_Near (Fitness_From_MSE (0.0), 1.0, "Fitness_From_MSE 0");
   end;

   ---------------------------------------------------------------------------
   -- Random gene / mutate / crossover / transpose
   ---------------------------------------------------------------------------
   Seed_RNG (State, 42);
   for H in Head_Len loop
      G := Random_Gene (State, H, False);
      Check (Gene_Is_Well_Formed (G), "random well-formed");
      Check (G.Length = Gene_Length_Of (H), "random length");
      Check (G.Head = H, "random head field");
   end loop;

   Seed_RNG (State, 99);
   for K in 1 .. 20 loop
      G := Random_Gene (State, 4, True);
      Check (Gene_Is_Well_Formed (G), "random eph well-formed");
      Mutate (G, State, 0.5, True);
      Check (Gene_Is_Well_Formed (G), "mutate preserves validity");
   end loop;

   Seed_RNG (State, 7);
   for K in 1 .. 15 loop
      G := Random_Gene (State, 5, False);
      G2 := Random_Gene (State, 5, False);
      Crossover_One_Point (G, G2, C1, C2, State);
      Check (Gene_Is_Well_Formed (C1), "xover child1 valid");
      Check (Gene_Is_Well_Formed (C2), "xover child2 valid");
      Check (C1.Length = G.Length and then C2.Length = G.Length, "xover len");
      Check (C1.Head = G.Head, "xover head");
   end loop;

   Seed_RNG (State, 3);
   for K in 1 .. 10 loop
      G := Random_Gene (State, 6, False);
      Transpose_Stub (G, State);
      Check (Gene_Is_Well_Formed (G), "transpose stub valid");
   end loop;

   Seed_RNG (State, 11);
   for K in 1 .. 12 loop
      G := Random_Gene (State, 4, False);
      L := ORF_Length (G);
      Check (L >= 1 and then L <= Natural (G.Length), "ORF bounds");
   end loop;

   ---------------------------------------------------------------------------
   -- Toy data
   ---------------------------------------------------------------------------
   Seed_RNG (State, 1);
   Data := Make_Toy_Data (Sum_AB, 8, State, -1.0, 1.0);
   for S of Data loop
      Check_Near (S.Target, S.A + S.B, "toy sum", 1.0E-12);
   end loop;
   Seed_RNG (State, 2);
   Data := Make_Toy_Data (Product_AB, 8, State, -1.0, 1.0);
   for S of Data loop
      Check_Near (S.Target, S.A * S.B, "toy prod", 1.0E-12);
   end loop;
   Seed_RNG (State, 3);
   Data := Make_Toy_Data (Diff_AB, 8, State, -1.0, 1.0);
   for S of Data loop
      Check_Near (S.Target, S.A - S.B, "toy diff", 1.0E-12);
   end loop;

   ---------------------------------------------------------------------------
   -- Evolution
   ---------------------------------------------------------------------------
   Seed_RNG (State, 5);
   declare
      D : constant Sample_Array :=
        Make_Toy_Data (Sum_AB, 10, State, -1.0, 1.0);
      Cfg0 : constant Config :=
        Default_Config
          (Pop_Size => 20, Generations => 0, Head => 3, Seed => 5);
      Cfg1 : constant Config :=
        Default_Config
          (Pop_Size       => 24,
           Generations    => 30,
           Head           => 3,
           Mutation_Rate  => 0.15,
           Crossover_Rate => 0.8,
           Seed           => 5);
   begin
      R := Evolve (D, Cfg0);
      F0 := R.Best_Fitness;
      Check (R.Generations_Run = 0, "evolve gens=0");
      Check (R.History_Length = 0, "history 0");
      R := Evolve (D, Cfg1);
      F1 := R.Best_Fitness;
      Check (R.Generations_Run = 30, "evolve gens=30");
      Check (R.Evaluations > 0, "evaluations > 0");
      Check (F1 >= F0 - 1.0E-9, "fitness nondecreasing vs init");
      Check (F1 > 0.5, "evolved fitness > 0.5 on a+b");
      Check (Gene_Is_Well_Formed (R.Best), "best well-formed");
   end;

   declare
      Cfg : constant Config :=
        Default_Config
          (Pop_Size => 30, Generations => 40, Head => 4, Seed => 123);
   begin
      R := Fit_Symbolic (Sum_AB, Cfg);
      Check (R.Best_Fitness > 0.8, "Fit_Symbolic a+b strong");
      R := Fit_Symbolic (Product_AB, Cfg);
      Check (R.Best_Fitness > 0.5, "Fit_Symbolic a*b improves");
   end;

   declare
      Perfect : Gene;
      D : Sample_Array (1 .. 6);
      St : RNG_State;
   begin
      Seed_RNG (St, 8);
      D := Make_Toy_Data (Sum_AB, 6, St);
      Perfect := Make_Gene (Sym ("+ababab"), 3);
      Check_Near (Fitness_Of (Perfect, D), 1.0, "perfect fitness 1");
   end;

   ---------------------------------------------------------------------------
   -- RNG
   ---------------------------------------------------------------------------
   declare
      S1, S2 : RNG_State;
      U1, U2 : Unit_Interval;
   begin
      Seed_RNG (S1, 12345);
      Seed_RNG (S2, 12345);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      Check (U1 = U2, "RNG reproducible");
      Check (Next_Natural (S1, 0, 0) = 0, "Next_Natural lo=hi");
      Check (Next_Natural (S1, 5, 5) = 5, "Next_Natural same");
   end;

   for K in 1 .. 30 loop
      declare
         St : RNG_State;
         N  : Natural;
      begin
         Seed_RNG (St, K * 17);
         N := Next_Natural (St, 3, 10);
         Check (N >= 3 and then N <= 10, "Next_Natural range");
      end;
   end loop;

   ---------------------------------------------------------------------------
   -- Invalid inputs
   ---------------------------------------------------------------------------
   begin
      G := Make_Gene (Sym ("+aba+ab"), 3);  -- function in tail
      Check (False, "should reject func in tail");
   exception
      when Invalid_Argument =>
         Check (True, "reject func in tail");
   end;

   begin
      G := Make_Gene (Sym ("ab"), 3);
      Check (False, "should reject wrong length");
   exception
      when Invalid_Argument =>
         Check (True, "reject wrong length");
      when Constraint_Error =>
         Check (True, "reject wrong length CE");
   end;

   ---------------------------------------------------------------------------
   -- Caps / random evaluate
   ---------------------------------------------------------------------------
   declare
      H : Head_Len := 1;
      Acc : Natural := 0;
   begin
      while H < Max_Head loop
         Acc := Acc + Natural (Gene_Length_Of (H));
         H := Head_Len'Succ (H);
      end loop;
      Acc := Acc + Natural (Gene_Length_Of (H));
      Check (Acc = 3 + 5 + 7 + 9 + 11 + 13, "sum gene lengths h=1..6");
   end;

   Seed_RNG (State, 77);
   for K in 1 .. 25 loop
      G := Random_Gene (State, 5, False);
      V := Evaluate (G, 1.0, -1.0);
      Check (abs (V) <= 1.0E30, "eval not huge");
   end loop;

   --  Mutate rate 0 leaves gene symbols unchanged (ephemeral untouched)
   Seed_RNG (State, 50);
   G := Random_Gene (State, 3, False);
   G2 := G;
   Mutate (G, State, 0.0, False);
   declare
      Same : Boolean := True;
   begin
      for I in 1 .. G.Length loop
         if G.Symbols (I) /= G2.Symbols (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "mutate rate 0 no change");
   end;

   Put_Line
     ("Passed:" & Natural'Image (Passed)
      & " Failed:" & Natural'Image (Failed));
   if Failed > 0 then
      raise Program_Error with "tests failed";
   end if;
end Tests;
