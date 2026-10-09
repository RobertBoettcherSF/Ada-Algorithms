--  test_reference.adb
--  ARC_Cache against a deliberately simple reference written from the
--  Megiddo-Modha paper ("ARC: A Self-Tuning, Low Overhead Replacement
--  Cache", FAST 2003, Fig. 4) plus the ZFS rule that a locked page is
--  never evicted (REPLACE takes the LRU *unlocked* page of the chosen list,
--  else of the other list). The four lists are plain arrays, MRU first,
--  searched linearly. 3,000 seeded random traces (seed 20261009) of
--  Put / Put_Locked / Get / Get_Locked / Unlock / Is_Locked over keys
--  0 .. 3 * capacity, capacity 1 .. 6; every Get result, value and
--  Is_Locked answer must agree, and Cache_Full_Of_Locked_Pages must be
--  raised exactly when the reference has no unlocked page to evict
--  (a trace stops at the first such exception: the cache state after it
--  is unspecified). Exhaustive: every trace of 6 Put / Get operations over
--  keys 0 .. 3 with capacity 2.
pragma Ada_2012;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Containers;
with Interfaces; use Interfaces;
with ARC_Cache;

procedure Test_Reference is
   function Hash (K : Integer) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type (K mod 1024));
   package Cache_Int is new ARC_Cache (Integer, Integer, Hash);
   use Cache_Int;

   Fails  : Natural := 0;
   Checks : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Checks := Checks + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   State : Unsigned_64 := 20261009;
   function Next (M : Positive) return Natural is
   begin
      State := State * 6364136223846793005 + 1442695040888963407;
      return Natural (Shift_Right (State, 33) mod Unsigned_64 (M));
   end Next;

   --  Reference ------------------------------------------------------------
   Max : constant := 16;
   type Key_Array is array (1 .. Max) of Integer;
   type Ref_List is record
      Len  : Natural := 0;
      Keys : Key_Array := (others => 0);   --  Keys (1) is MRU
   end record;
   type Which is (T1, T2, B1, B2);
   type Ref_Lists is array (Which) of Ref_List;
   type Bool_Array is array (0 .. 31) of Boolean;
   type Int_Array is array (0 .. 31) of Integer;
   type Ref_Cache is record
      C      : Positive := 1;
      P      : Natural := 0;
      L      : Ref_Lists;
      Locked : Bool_Array := (others => False);
      Value  : Int_Array := (others => 0);
   end record;

   function Find (R : Ref_Cache; W : Which; K : Integer) return Natural is
   begin
      for I in 1 .. R.L (W).Len loop
         if R.L (W).Keys (I) = K then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   procedure Remove_At (R : in out Ref_Cache; W : Which; I : Positive) is
   begin
      for J in I .. R.L (W).Len - 1 loop
         R.L (W).Keys (J) := R.L (W).Keys (J + 1);
      end loop;
      R.L (W).Len := R.L (W).Len - 1;
   end Remove_At;

   procedure Push_MRU (R : in out Ref_Cache; W : Which; K : Integer) is
   begin
      for J in reverse 1 .. R.L (W).Len loop
         R.L (W).Keys (J + 1) := R.L (W).Keys (J);
      end loop;
      R.L (W).Keys (1) := K;
      R.L (W).Len := R.L (W).Len + 1;
   end Push_MRU;

   --  Move the LRU unlocked page of From to the MRU end of To
   function Evict (R : in out Ref_Cache; From, To : Which) return Boolean is
   begin
      for I in reverse 1 .. R.L (From).Len loop
         if not R.Locked (R.L (From).Keys (I)) then
            declare
               K : constant Integer := R.L (From).Keys (I);
            begin
               Remove_At (R, From, I);
               Push_MRU (R, To, K);
               return True;
            end;
         end if;
      end loop;
      return False;
   end Evict;

   Full : exception;

   procedure Ref_Replace (R : in out Ref_Cache; In_B2 : Boolean) is
   begin
      if R.L (T1).Len >= 1
        and then (R.L (T1).Len > R.P or else (In_B2 and then R.L (T1).Len = R.P))
      then
         if not Evict (R, T1, B1) and then not Evict (R, T2, B2) then
            raise Full;
         end if;
      else
         if not Evict (R, T2, B2) and then not Evict (R, T1, B1) then
            raise Full;
         end if;
      end if;
   end Ref_Replace;

   procedure Ref_Put (R : in out Ref_Cache; K, V : Integer; Lock : Boolean) is
      I : Natural;
   begin
      for W in T1 .. T2 loop
         I := Find (R, W, K);
         if I > 0 then                                      --  case I
            Remove_At (R, W, I);
            Push_MRU (R, T2, K);
            R.Value (K) := V;
            R.Locked (K) := R.Locked (K) or Lock;
            return;
         end if;
      end loop;
      I := Find (R, B1, K);
      if I > 0 then                                         --  case II
         declare
            D : Natural := 1;
         begin
            if R.L (B1).Len < R.L (B2).Len then
               D := R.L (B2).Len / R.L (B1).Len;
            end if;
            R.P := Natural'Min (R.C, R.P + D);
         end;
         Ref_Replace (R, False);
         Remove_At (R, B1, Find (R, B1, K));
         Push_MRU (R, T2, K);
         R.Value (K) := V;
         R.Locked (K) := Lock;
         return;
      end if;
      I := Find (R, B2, K);
      if I > 0 then                                         --  case III
         declare
            D : Natural := 1;
         begin
            if R.L (B2).Len < R.L (B1).Len then
               D := R.L (B1).Len / R.L (B2).Len;
            end if;
            R.P := Natural'Max (0, R.P - D);
         end;
         Ref_Replace (R, True);
         Remove_At (R, B2, Find (R, B2, K));
         Push_MRU (R, T2, K);
         R.Value (K) := V;
         R.Locked (K) := Lock;
         return;
      end if;
      --  case IV
      if R.L (T1).Len + R.L (B1).Len = R.C then
         if R.L (T1).Len < R.C then
            Remove_At (R, B1, R.L (B1).Len);
            Ref_Replace (R, False);
         else
            declare
               Done : Boolean := False;
            begin
               for J in reverse 1 .. R.L (T1).Len loop
                  if not R.Locked (R.L (T1).Keys (J)) then
                     Remove_At (R, T1, J);
                     Done := True;
                     exit;
                  end if;
               end loop;
               if not Done then
                  raise Full;
               end if;
            end;
         end if;
      else
         declare
            Total : constant Natural :=
              R.L (T1).Len + R.L (T2).Len + R.L (B1).Len + R.L (B2).Len;
         begin
            if Total >= R.C then
               if Total = 2 * R.C then
                  Remove_At (R, B2, R.L (B2).Len);
               end if;
               Ref_Replace (R, False);
            end if;
         end;
      end if;
      Push_MRU (R, T1, K);
      R.Value (K) := V;
      R.Locked (K) := Lock;
   end Ref_Put;

   function Ref_Get (R : in out Ref_Cache; K : Integer; V : out Integer;
                     Lock : Boolean) return Boolean is
      I : Natural;
   begin
      V := 0;
      for W in T1 .. T2 loop
         I := Find (R, W, K);
         if I > 0 then
            Remove_At (R, W, I);
            Push_MRU (R, T2, K);
            V := R.Value (K);
            R.Locked (K) := R.Locked (K) or Lock;
            return True;
         end if;
      end loop;
      return False;
   end Ref_Get;

   function Resident (R : Ref_Cache; K : Integer) return Boolean is
     (Find (R, T1, K) > 0 or else Find (R, T2, K) > 0);

   --  One operation on both; False when the trace must stop
   function Step (Cache_Obj : in out Cache; R : in out Ref_Cache;
                  Op, K, V : Integer; Tag : String) return Boolean is
      Got_Full, Ref_Full : Boolean := False;
   begin
      case Op is
         when 0 | 1 =>
            begin
               Ref_Put (R, K, V, Op = 1);
            exception
               when Full => Ref_Full := True;
            end;
            begin
               if Op = 1 then
                  Put_Locked (Cache_Obj, K, V);
               else
                  Put (Cache_Obj, K, V);
               end if;
            exception
               when Cache_Full_Of_Locked_Pages => Got_Full := True;
            end;
            Check (Got_Full = Ref_Full, Tag & " full-of-locked-pages agreement");
            return not (Got_Full or Ref_Full);
         when 2 | 3 =>
            declare
               RV, GV : Integer;
               RH     : constant Boolean := Ref_Get (R, K, RV, Op = 3);
               GH     : Boolean;
            begin
               if Op = 3 then
                  GH := Get_Locked (Cache_Obj, K, GV);
               else
                  GH := Get (Cache_Obj, K, GV);
               end if;
               Check (GH = RH, Tag & " hit/miss key" & Integer'Image (K));
               if GH and RH then
                  Check (GV = RV, Tag & " value key" & Integer'Image (K));
               end if;
            end;
         when 4 =>
            Unlock (Cache_Obj, K);
            if Resident (R, K) then
               R.Locked (K) := False;
            end if;
         when others =>
            Check (Is_Locked (Cache_Obj, K) = (Resident (R, K) and then R.Locked (K)),
                   Tag & " Is_Locked key" & Integer'Image (K));
      end case;
      return True;
   end Step;

   Value_Seq : Integer := 0;
begin
   --  Random traces
   for T in 1 .. 3_000 loop
      declare
         Cap  : constant Positive := 1 + Next (6);
         C    : Cache (Ada.Containers.Count_Type (Cap));
         R    : Ref_Cache;
         Keys : constant Positive := 3 * Cap + 1;
         --  few locks, so long traces run before the cache fills with them
         Lock_Ops : constant Boolean := Next (3) = 0;
         Op   : Integer;
      begin
         R.C := Cap;
         for S in 1 .. 200 loop
            Op := Next (12);
            Op := (if Op <= 3 then 0 elsif Op <= 8 then 2
                   elsif Op = 9 then (if Lock_Ops then 1 else 0)
                   elsif Op = 10 then (if Lock_Ops then 3 else 4)
                   else (if Next (2) = 0 then 4 else 5));
            Value_Seq := Value_Seq + 1;
            exit when not Step (C, R, Op, Next (Keys), Value_Seq,
                                "trace" & Integer'Image (T) & " step" & Integer'Image (S));
            if Lock_Ops and then Next (4) = 0 then
               exit when not Step (C, R, 4, Next (Keys), 0, "unlock");
            end if;
         end loop;
      end;
   end loop;

   --  Exhaustive: all 8 ** 6 traces of Put / Get over keys 0 .. 3, capacity 2
   for Code in 0 .. 8 ** 6 - 1 loop
      declare
         C   : Cache (2);
         R   : Ref_Cache;
         X   : Natural := Code;
         Ok  : Boolean;
      begin
         R.C := 2;
         for S in 1 .. 6 loop
            Value_Seq := Value_Seq + 1;
            Ok := Step (C, R, 2 * ((X mod 8) / 4), X mod 4, Value_Seq, "exhaustive");
            X := X / 8;
         end loop;
         pragma Unreferenced (Ok);
      end;
   end loop;

   if Fails = 0 then
      Put_Line ("PASS ARC reference comparison:" & Natural'Image (Checks)
                & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Natural'Image (Fails) & " of" & Natural'Image (Checks));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Test_Reference;
