--  Rainflow_Counting body — turning points, four-point extraction,
--  closed/wrap option, Miner's damage helpers.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Rainflow_Counting
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Range_Of (X, Y : Real) return Non_Negative is
   begin
      return abs (X - Y);
   end Range_Of;

   function Make_Cycle
     (From, To : Real;
      Cnt      : Non_Negative) return Cycle
   is
      R : constant Non_Negative := abs (To - From);
   begin
      return
        (From_Level => From,
         To_Level   => To,
         Range_Val  => R,
         Amplitude  => R / 2.0,
         Mean       => (From + To) / 2.0,
         Count      => Cnt);
   end Make_Cycle;

   procedure Append_Cycle
     (Result : in out Cycle_Result;
      Item   : Cycle)
   is
   begin
      if Result.Length = Max_N then
         raise Capacity_Exceeded;
      end if;
      Result.Length := Result.Length + 1;
      Result.Items (Result.Length) := Item;
   end Append_Cycle;

   --  True iff [min(B,C), max(B,C)] ⊆ [min(A,D), max(A,D)].
   function Is_Rainflow_Cycle
     (A, B, C, D : Real) return Boolean
   is
      Lo_AD : constant Real := Real'Min (A, D);
      Hi_AD : constant Real := Real'Max (A, D);
      Lo_BC : constant Real := Real'Min (B, C);
      Hi_BC : constant Real := Real'Max (B, C);
   begin
      return Lo_AD <= Lo_BC
        and then Hi_BC <= Hi_AD
        and then Hi_BC > Lo_BC;  --  reject zero-range B=C
   end Is_Rainflow_Cycle;

   -------------------------------------------------------------------------
   -- Turning points
   -------------------------------------------------------------------------

   function Extract_Turning_Points (History : Real_Array) return Real_Array is
      N : constant Natural := History'Length;
   begin
      if N = 0 then
         declare
            Empty : Real_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      if N > Max_N then
         raise Capacity_Exceeded;
      end if;

      --  Pass 1: collapse consecutive equal values into a work buffer.
      declare
         Work   : Real_Array (1 .. N);
         WLen   : Natural := 0;
         Out_Buf : Real_Array (1 .. N);
         OLen   : Natural := 0;
      begin
         for I in History'Range loop
            if WLen = 0 then
               WLen := 1;
               Work (1) := History (I);
            elsif not Near (History (I), Work (WLen)) then
               WLen := WLen + 1;
               Work (WLen) := History (I);
            end if;
         end loop;

         if WLen <= 2 then
            return Work (1 .. WLen);
         end if;

         --  Pass 2: keep first, last, and strict local extrema.
         OLen := 1;
         Out_Buf (1) := Work (1);

         for I in 2 .. WLen - 1 loop
            declare
               Prev : constant Real := Work (I - 1);
               Curr : constant Real := Work (I);
               Next : constant Real := Work (I + 1);
               Peak : constant Boolean :=
                 Curr > Prev and then Curr > Next;
               Valley : constant Boolean :=
                 Curr < Prev and then Curr < Next;
            begin
               --  After collapsing equals, non-strict plateaus are gone;
               --  keep only peaks and valleys (direction changes).
               if Peak or else Valley then
                  OLen := OLen + 1;
                  Out_Buf (OLen) := Curr;
               end if;
            end;
         end loop;

         OLen := OLen + 1;
         Out_Buf (OLen) := Work (WLen);

         --  If first two became equal after dropping interiors, rare;
         --  also drop consecutive equals that can appear if first equals
         --  a kept extremum (should not with Near collapse). Final pass:
         declare
            Final : Real_Array (1 .. OLen);
            FLen  : Natural := 0;
         begin
            for I in 1 .. OLen loop
               if FLen = 0 then
                  FLen := 1;
                  Final (1) := Out_Buf (I);
               elsif not Near (Out_Buf (I), Final (FLen)) then
                  FLen := FLen + 1;
                  Final (FLen) := Out_Buf (I);
               end if;
            end loop;
            return Final (1 .. FLen);
         end;
      end;
   end Extract_Turning_Points;

   -------------------------------------------------------------------------
   -- Four-point method
   -------------------------------------------------------------------------

   procedure Count_Cycles_Four_Point
     (Turning_Points    : Real_Array;
      Result            : out Cycle_Result;
      Include_Residuals : Boolean := True)
   is
      N : constant Natural := Turning_Points'Length;
      Buf : Real_Array (1 .. Max_N);
      Len : Natural := 0;
      Found : Boolean;
      I : Natural;
   begin
      Result.Length := 0;

      if N = 0 then
         return;
      end if;

      if N > Max_N then
         raise Capacity_Exceeded;
      end if;

      for K in Turning_Points'Range loop
         Len := Len + 1;
         Buf (Len) := Turning_Points (K);
      end loop;

      --  Repeatedly scan for the first rainflow cycle A-B-C-D.
      loop
         Found := False;
         I := 1;
         while I + 3 <= Len loop
            declare
               A : constant Real := Buf (I);
               B : constant Real := Buf (I + 1);
               C : constant Real := Buf (I + 2);
               D : constant Real := Buf (I + 3);
            begin
               if Is_Rainflow_Cycle (A, B, C, D) then
                  Append_Cycle (Result, Make_Cycle (B, C, 1.0));
                  --  Remove B and C (indices I+1 and I+2).
                  for J in I + 1 .. Len - 2 loop
                     Buf (J) := Buf (J + 2);
                  end loop;
                  Len := Len - 2;
                  Found := True;
                  exit;  --  restart from beginning
               end if;
            end;
            I := I + 1;
         end loop;
         exit when not Found;
      end loop;

      --  Residual half-cycles from remaining consecutive pairs.
      if Include_Residuals and then Len >= 2 then
         for K in 1 .. Len - 1 loop
            Append_Cycle (Result, Make_Cycle (Buf (K), Buf (K + 1), 0.5));
         end loop;
      end if;
   end Count_Cycles_Four_Point;

   -------------------------------------------------------------------------
   -- Closed / wrap helper: rotate to largest peak, append that peak
   -------------------------------------------------------------------------

   function Prepare_Closed (TP : Real_Array) return Real_Array is
      N : constant Natural := TP'Length;
   begin
      if N = 0 then
         declare
            Empty : Real_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      if N = 1 then
         return TP;
      end if;

      --  Find index of largest peak (maximum value).
      declare
         Max_Idx : Positive := TP'First;
         Max_Val : Real := TP (TP'First);
         Start   : Positive;
         Closed_Len : constant Positive := N + 1;
         Closed_Arr : Real_Array (1 .. Closed_Len);
         Pos     : Positive := 1;
      begin
         for I in TP'Range loop
            if TP (I) > Max_Val then
               Max_Val := TP (I);
               Max_Idx := I;
            end if;
         end loop;

         --  Rotate so Max_Idx is first, then append Max_Val to close.
         Start := Max_Idx;
         for K in 0 .. N - 1 loop
            declare
               Src : constant Positive :=
                 TP'First + ((Start - TP'First + K) mod N);
            begin
               Closed_Arr (Pos) := TP (Src);
               Pos := Pos + 1;
            end;
         end loop;
         Closed_Arr (Closed_Len) := Max_Val;

         --  Collapse consecutive equals introduced by wrap (e.g. same
         --  endpoint values at both ends of the original block).
         declare
            Collapsed : Real_Array (1 .. Closed_Len);
            CLen      : Natural := 0;
         begin
            for I in 1 .. Closed_Len loop
               if CLen = 0 then
                  CLen := 1;
                  Collapsed (1) := Closed_Arr (I);
               elsif not Near (Closed_Arr (I), Collapsed (CLen)) then
                  CLen := CLen + 1;
                  Collapsed (CLen) := Closed_Arr (I);
               end if;
            end loop;
            return Collapsed (1 .. CLen);
         end;
      end;
   end Prepare_Closed;

   procedure Count_Cycles
     (History           : Real_Array;
      Result            : out Cycle_Result;
      Include_Residuals : Boolean := True;
      Closed            : Boolean := False)
   is
      TP : constant Real_Array := Extract_Turning_Points (History);
   begin
      if Closed then
         declare
            Closed_TP : constant Real_Array := Prepare_Closed (TP);
         begin
            --  Closed blocks ideally leave no residuals; still honour flag.
            Count_Cycles_Four_Point
              (Closed_TP, Result, Include_Residuals => Include_Residuals);
         end;
      else
         Count_Cycles_Four_Point
           (TP, Result, Include_Residuals => Include_Residuals);
      end if;
   end Count_Cycles;

   -------------------------------------------------------------------------
   -- Miner's rule
   -------------------------------------------------------------------------

   function Power_Law_Life
     (Amplitude : Positive_Real;
      C_Const   : Positive_Real;
      M_Exp     : Positive_Real) return Positive_Real
   is
   begin
      --  N = C / S^m  via exp(m * log S)
      return C_Const / Exp (M_Exp * Log (Amplitude));
   end Power_Law_Life;

   function Total_Damage
     (Cycles  : Cycle_Result;
      C_Const : Positive_Real;
      M_Exp   : Positive_Real) return Non_Negative
   is
      D : Non_Negative := 0.0;
   begin
      for I in 1 .. Cycles.Length loop
         declare
            Amp : constant Non_Negative := Cycles.Items (I).Amplitude;
            Ni  : Positive_Real;
         begin
            if Amp > 0.0 then
               Ni := Power_Law_Life (Amp, C_Const, M_Exp);
               D := D + Cycles.Items (I).Count / Ni;
            end if;
         end;
      end loop;
      return D;
   end Total_Damage;

   function Total_Damage_With
     (Cycles : Cycle_Result;
      Life   : not null access function
                   (Amplitude : Positive_Real) return Positive_Real)
      return Non_Negative
   is
      D : Non_Negative := 0.0;
   begin
      for I in 1 .. Cycles.Length loop
         declare
            Amp : constant Non_Negative := Cycles.Items (I).Amplitude;
            Ni  : Positive_Real;
         begin
            if Amp > 0.0 then
               Ni := Life (Amp);
               D := D + Cycles.Items (I).Count / Ni;
            end if;
         end;
      end loop;
      return D;
   end Total_Damage_With;

   function Full_Cycle_Count (Result : Cycle_Result) return Non_Negative is
      S : Non_Negative := 0.0;
   begin
      for I in 1 .. Result.Length loop
         if Result.Items (I).Count >= 1.0 - Epsilon_Tol then
            S := S + Result.Items (I).Count;
         end if;
      end loop;
      return S;
   end Full_Cycle_Count;

   function Half_Cycle_Count (Result : Cycle_Result) return Non_Negative is
      S : Non_Negative := 0.0;
   begin
      for I in 1 .. Result.Length loop
         if Near (Result.Items (I).Count, 0.5) then
            S := S + Result.Items (I).Count;
         end if;
      end loop;
      return S;
   end Half_Cycle_Count;

   function Equivalent_Full_Cycles
     (Result : Cycle_Result) return Non_Negative
   is
      S : Non_Negative := 0.0;
   begin
      for I in 1 .. Result.Length loop
         S := S + Result.Items (I).Count;
      end loop;
      return S;
   end Equivalent_Full_Cycles;

end Rainflow_Counting;
