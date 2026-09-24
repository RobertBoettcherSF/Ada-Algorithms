--  Tabu_Search body — short-term tabu list, aspiration, bit / TSP / partition.

pragma Ada_2022;

package body Tabu_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Tabu list
   ---------------------------------------------------------------------------

   procedure Clear (L : in out Tabu_List) is
   begin
      for I in L.Buf'Range loop
         L.Buf (I).Active := False;
         L.Buf (I).Attr   := 0;
         L.Buf (I).Expiry := 0;
      end loop;
      L.Next  := 1;
      L.Count := 0;
   end Clear;

   procedure Reset_Clock (L : in out Tabu_List; Clock : Natural := 0) is
   begin
      L.Clock := Clock;
   end Reset_Clock;

   procedure Set_Clock (L : in out Tabu_List; Clock : Natural) is
   begin
      L.Clock := Clock;
   end Set_Clock;

   procedure Push
     (L      : in out Tabu_List;
      Attr   : Natural;
      Tenure : Positive)
   is
      Slot : constant Positive := L.Next;
   begin
      L.Buf (Slot) :=
        (Attr   => Attr,
         Expiry => L.Clock + Natural (Tenure),
         Active => True);
      if L.Next = L.Capacity then
         L.Next := 1;
      else
         L.Next := L.Next + 1;
      end if;
      if L.Count < L.Capacity then
         L.Count := L.Count + 1;
      end if;
   end Push;

   function Contains (L : Tabu_List; Attr : Natural) return Boolean is
   begin
      for I in L.Buf'Range loop
         if L.Buf (I).Active
           and then L.Buf (I).Attr = Attr
           and then L.Clock < L.Buf (I).Expiry
         then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Is_Admissible
     (L              : Tabu_List;
      Attr           : Natural;
      Candidate_Cost : Real;
      Best_Cost      : Real;
      Use_Aspiration : Boolean) return Boolean
   is
   begin
      if not Contains (L, Attr) then
         return True;
      end if;
      if Use_Aspiration and then Candidate_Cost < Best_Cost then
         return True;
      end if;
      return False;
   end Is_Admissible;

   function Active_Count (L : Tabu_List) return Natural is
      N : Natural := 0;
   begin
      for I in L.Buf'Range loop
         if L.Buf (I).Active and then L.Clock < L.Buf (I).Expiry then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Active_Count;

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Hamming_Distance (A, B : Bit_String) return Natural is
      D : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Hamming_Distance;

   function Zero_Count (Bits : Bit_String) return Natural is
      Z : Natural := 0;
   begin
      for B of Bits loop
         if not B then
            Z := Z + 1;
         end if;
      end loop;
      return Z;
   end Zero_Count;

   function Ones_Count (Bits : Bit_String) return Natural is
   begin
      return Bits'Length - Zero_Count (Bits);
   end Ones_Count;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      R : Bit_String := Bits;
   begin
      R (Index) := not R (Index);
      return R;
   end Flip_Bit;

   function To_Result (R : Bit_Result) return Result is
   begin
      return
        (Best_Cost         => R.Best_Cost,
         Final_Cost        => R.Final_Cost,
         Iters             => R.Iters,
         Moves_Accepted    => R.Moves_Accepted,
         Aspiration_Count  => R.Aspiration_Count,
         Tabu_Reject_Count => R.Tabu_Reject_Count);
   end To_Result;

   function Minimize_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Cap    : constant Positive :=
        Positive'Min (Cfg.Max_Tabu, Max_Tabu_Cap);
      Tabu   : Tabu_List (Cap);
      Cur    : Bit_String (1 .. N) := Start;
      Best   : Bit_String (1 .. N) := Start;
      Cost   : Real := Real (Hamming_Distance (Cur, Target));
      Best_C : Real := Cost;
      R      : Bit_Result;
      Found  : Boolean;
      Best_N : Bit_String (1 .. N);
      Best_A : Natural;
      Best_Nc : Real;
      Cand   : Bit_String (1 .. N);
      Cand_C : Real;
      Attr   : Natural;
      Was_Tabu : Boolean;
   begin
      Clear (Tabu);
      Reset_Clock (Tabu, 0);

      if Best_C = 0.0 then
         R.N          := N;
         R.Best_Cost  := Best_C;
         R.Final_Cost := Cost;
         for I in 1 .. N loop
            R.Best_Bits (I) := Best (I);
         end loop;
         return R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Set_Clock (Tabu, Iter);
         Found   := False;
         Best_Nc := Real'Last;
         Best_A  := 0;
         Best_N  := Cur;

         for K in 1 .. N loop
            Cand   := Flip_Bit (Cur, K);
            Cand_C := Real (Hamming_Distance (Cand, Target));
            Attr   := K;
            if Is_Admissible
              (Tabu, Attr, Cand_C, Best_C, Cfg.Use_Aspiration)
            then
               if (not Found) or else Cand_C < Best_Nc then
                  Found   := True;
                  Best_Nc := Cand_C;
                  Best_N  := Cand;
                  Best_A  := Attr;
               end if;
            else
               R.Tabu_Reject_Count := R.Tabu_Reject_Count + 1;
            end if;
         end loop;

         exit when not Found;

         Was_Tabu := Contains (Tabu, Best_A);
         if Was_Tabu and then Best_Nc < Best_C then
            R.Aspiration_Count := R.Aspiration_Count + 1;
         end if;

         Cur  := Best_N;
         Cost := Best_Nc;
         Push (Tabu, Best_A, Cfg.Tenure);
         R.Moves_Accepted := R.Moves_Accepted + 1;
         R.Iters := Iter;

         if Cost < Best_C then
            Best_C := Cost;
            Best   := Cur;
         end if;

         exit when Best_C = 0.0;
      end loop;

      R.N          := N;
      R.Best_Cost  := Best_C;
      R.Final_Cost := Cost;
      for I in 1 .. N loop
         R.Best_Bits (I) := Best (I);
      end loop;
      return R;
   end Minimize_Hamming;

   function Minimize_OneMax
     (Start : Bit_String;
      Cfg   : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Target : constant Bit_String (1 .. N) := [others => True];
   begin
      return Minimize_Hamming (Start, Target, Cfg);
   end Minimize_OneMax;

   ---------------------------------------------------------------------------
   -- TSP 2-opt
   ---------------------------------------------------------------------------

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative is
      Len : Real := 0.0;
      A, B : City_Index;
   begin
      for I in T'First .. T'Last - 1 loop
         A := T (I);
         B := T (I + 1);
         Len := Len + Real (D (A, B));
      end loop;
      A := T (T'Last);
      B := T (T'First);
      Len := Len + Real (D (A, B));
      return Non_Negative (Len);
   end Tour_Length;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour is
      R : Tour := T;
      Lo : City_Index := I + 1;
      Hi : City_Index := J;
      Tmp : City_Index;
   begin
      --  Reverse positions Lo .. Hi
      while Lo < Hi loop
         Tmp := R (Lo);
         R (Lo) := R (Hi);
         R (Hi) := Tmp;
         Lo := Lo + 1;
         Hi := Hi - 1;
      end loop;
      return R;
   end Apply_2Opt;

   function Encode_2Opt_Attr (I, J : City_Index) return Natural is
   begin
      return Natural (I) * (Max_Cities + 1) + Natural (J);
   end Encode_2Opt_Attr;

   function To_Result (R : TSP_Result) return Result is
   begin
      return
        (Best_Cost         => Real (R.Best_Length),
         Final_Cost        => Real (R.Final_Length),
         Iters             => R.Iters,
         Moves_Accepted    => R.Moves_Accepted,
         Aspiration_Count  => R.Aspiration_Count,
         Tabu_Reject_Count => R.Tabu_Reject_Count);
   end To_Result;

   function Minimize_TSP
     (D     : Dist_Matrix;
      Start : Tour;
      Cfg   : Config) return TSP_Result
   is
      N      : constant City_Count := Start'Length;
      Last_C : constant City_Index := City_Index (N);
      Cap    : constant Positive :=
        Positive'Min (Cfg.Max_Tabu, Max_Tabu_Cap);
      Tabu   : Tabu_List (Cap);
      Cur    : Tour (1 .. Last_C) := Start;
      Best   : Tour (1 .. Last_C) := Start;
      Len    : Non_Negative := Tour_Length (Cur, D);
      Best_L : Non_Negative := Len;
      R      : TSP_Result;
      Found  : Boolean;
      Best_T : Tour (1 .. Last_C);
      Best_A : Natural;
      Best_Lc : Non_Negative;
      Cand   : Tour (1 .. Last_C);
      Cand_L : Non_Negative;
      Attr   : Natural;
      Was_Tabu : Boolean;
      I, J   : City_Index;
   begin
      Clear (Tabu);
      Reset_Clock (Tabu, 0);

      for Iter in 1 .. Cfg.Max_Iterations loop
         Set_Clock (Tabu, Iter);
         Found   := False;
         Best_Lc := Non_Negative'Last;
         Best_A  := 0;
         Best_T  := Cur;

         --  Enumerate 2-opt moves: I < J-1 so segment has length ≥ 1
         for II in 1 .. Natural (N) - 2 loop
            I := City_Index (II);
            for JJ in II + 2 .. Natural (N) loop
               --  Avoid full-tour reverse equivalent when closed; still OK
               J := City_Index (JJ);
               if I = 1 and then J = Last_C then
                  null;  -- reversing whole tour is identity up to direction
               else
                  Cand   := Apply_2Opt (Cur, I, J);
                  Cand_L := Tour_Length (Cand, D);
                  Attr   := Encode_2Opt_Attr (I, J);
                  if Is_Admissible
                    (Tabu, Attr, Real (Cand_L), Real (Best_L),
                     Cfg.Use_Aspiration)
                  then
                     if (not Found) or else Cand_L < Best_Lc then
                        Found   := True;
                        Best_Lc := Cand_L;
                        Best_T  := Cand;
                        Best_A  := Attr;
                     end if;
                  else
                     R.Tabu_Reject_Count := R.Tabu_Reject_Count + 1;
                  end if;
               end if;
            end loop;
         end loop;

         exit when not Found;

         Was_Tabu := Contains (Tabu, Best_A);
         if Was_Tabu and then Best_Lc < Best_L then
            R.Aspiration_Count := R.Aspiration_Count + 1;
         end if;

         Cur := Best_T;
         Len := Best_Lc;
         Push (Tabu, Best_A, Cfg.Tenure);
         R.Moves_Accepted := R.Moves_Accepted + 1;
         R.Iters := Iter;

         if Len < Best_L then
            Best_L := Len;
            Best   := Cur;
         end if;
      end loop;

      R.N            := N;
      R.Best_Length  := Best_L;
      R.Final_Length := Len;
      for K in Best'Range loop
         R.Best_Tour (K) := Best (K);
      end loop;
      return R;
   end Minimize_TSP;

   ---------------------------------------------------------------------------
   -- Number partitioning
   ---------------------------------------------------------------------------

   function Partition_Cost
     (W : Weights; A : Assignment) return Non_Negative
   is
      Sum_A : Real := 0.0;
      Sum_B : Real := 0.0;
      Diff  : Real;
   begin
      for I in W'Range loop
         if A (I - W'First + A'First) then
            Sum_A := Sum_A + Real (W (I));
         else
            Sum_B := Sum_B + Real (W (I));
         end if;
      end loop;
      Diff := abs (Sum_A - Sum_B);
      return Non_Negative (Diff);
   end Partition_Cost;

   function To_Result (R : Partition_Result) return Result is
   begin
      return
        (Best_Cost         => Real (R.Best_Cost),
         Final_Cost        => Real (R.Final_Cost),
         Iters             => R.Iters,
         Moves_Accepted    => R.Moves_Accepted,
         Aspiration_Count  => R.Aspiration_Count,
         Tabu_Reject_Count => R.Tabu_Reject_Count);
   end To_Result;

   function Minimize_Partition
     (W     : Weights;
      Start : Assignment;
      Cfg   : Config) return Partition_Result
   is
      N      : constant Part_Count := W'Length;
      Cap    : constant Positive :=
        Positive'Min (Cfg.Max_Tabu, Max_Tabu_Cap);
      Tabu   : Tabu_List (Cap);
      Cur    : Assignment (1 .. N) := Start;
      Best   : Assignment (1 .. N) := Start;
      Cost   : Non_Negative := Partition_Cost (W, Cur);
      Best_C : Non_Negative := Cost;
      R      : Partition_Result;
      Found  : Boolean;
      Best_A_Asg : Assignment (1 .. N);
      Best_Attr  : Natural;
      Best_Nc    : Non_Negative;
      Cand       : Assignment (1 .. N);
      Cand_C     : Non_Negative;
      Attr       : Natural;
      Was_Tabu   : Boolean;
   begin
      Clear (Tabu);
      Reset_Clock (Tabu, 0);

      if Best_C = 0.0 then
         R.N          := N;
         R.Best_Cost  := Best_C;
         R.Final_Cost := Cost;
         for I in 1 .. N loop
            R.Best_Assign (I) := Best (I);
         end loop;
         return R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Set_Clock (Tabu, Iter);
         Found   := False;
         Best_Nc := Non_Negative'Last;
         Best_Attr := 0;
         Best_A_Asg := Cur;

         for K in 1 .. N loop
            Cand := Cur;
            Cand (K) := not Cand (K);
            Cand_C := Partition_Cost (W, Cand);
            Attr := K;
            if Is_Admissible
              (Tabu, Attr, Real (Cand_C), Real (Best_C), Cfg.Use_Aspiration)
            then
               if (not Found) or else Cand_C < Best_Nc then
                  Found   := True;
                  Best_Nc := Cand_C;
                  Best_A_Asg := Cand;
                  Best_Attr  := Attr;
               end if;
            else
               R.Tabu_Reject_Count := R.Tabu_Reject_Count + 1;
            end if;
         end loop;

         exit when not Found;

         Was_Tabu := Contains (Tabu, Best_Attr);
         if Was_Tabu and then Best_Nc < Best_C then
            R.Aspiration_Count := R.Aspiration_Count + 1;
         end if;

         Cur  := Best_A_Asg;
         Cost := Best_Nc;
         Push (Tabu, Best_Attr, Cfg.Tenure);
         R.Moves_Accepted := R.Moves_Accepted + 1;
         R.Iters := Iter;

         if Cost < Best_C then
            Best_C := Cost;
            Best   := Cur;
         end if;

         exit when Best_C = 0.0;
      end loop;

      R.N         := N;
      R.Best_Cost := Best_C;
      R.Final_Cost := Cost;
      for I in 1 .. N loop
         R.Best_Assign (I) := Best (I);
      end loop;
      return R;
   end Minimize_Partition;

end Tabu_Search;
