--  test_reference.adb
--  Calendar against a deliberately simple reference: a list of active
--  reservations (start clipped to the window start after Move_Forward,
--  expired ones dropped) and, for each query, the maximum over every time
--  point of the sum of covering reservations. 2,000 seeded random
--  operation sequences (seed 20261009) of reserve / delete / move / query /
--  check, capacity 1 .. 24, at most 1 .. 12 reservations.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Interfaces; use Interfaces;
with Top_Nodes_Algorithm; use Top_Nodes_Algorithm;

procedure Test_Reference is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
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

   type Ref_Res is record
      Active : Boolean := False;
      S, E   : Time_Point := 0;
      Amount : Resource_Amount := 0;
   end record;
   type Ref_Array is array (1 .. 12) of Ref_Res;

   procedure Run_Sequence (Cap, Max_R : Positive) is
      Cal   : Calendar (Cap, Max_R);
      Ref   : Ref_Array;
      Start : Time_Point := 0;

      function Ref_Max (S, E : Time_Point) return Resource_Amount is
         Best : Resource_Amount := 0;
         Sum  : Resource_Amount;
      begin
         if S > E then
            return 0;
         end if;
         for T in S .. E loop
            Sum := 0;
            for R of Ref loop
               if R.Active and then R.S <= T and then T <= R.E then
                  Sum := Sum + R.Amount;
               end if;
            end loop;
            if Sum > Best then
               Best := Sum;
            end if;
         end loop;
         return Best;
      end Ref_Max;

      function Ref_Free return Natural is
         N : Natural := 0;
      begin
         for K in 1 .. Max_R loop
            if not Ref (K).Active then
               N := N + 1;
            end if;
         end loop;
         return N;
      end Ref_Free;
   begin
      Initialize (Cal);
      for Op in 1 .. 60 loop
         declare
            A  : constant Time_Point := Start + Time_Point (Next (Cap));
            B  : constant Time_Point := Start + Time_Point (Next (Cap));
            S  : constant Time_Point := Time_Point'Min (A, B);
            E  : constant Time_Point := Time_Point'Max (A, B);
            Am : constant Resource_Amount := Resource_Amount (Next (10));
         begin
            case Next (5) is
               when 0 | 1 =>
                  declare
                     ID : Reservation_ID;
                     Ok : Boolean;
                  begin
                     Reserve (Cal, S, E, Am, ID, Ok);
                     Check (Ok = (Ref_Free > 0), "reserve success");
                     if Ok then
                        Check (Integer (ID) <= Max_R
                               and then not Ref (Integer (ID)).Active,
                               "reserve returned a used or out-of-range ID");
                        if Integer (ID) <= Max_R then
                           Ref (Integer (ID)) := (True, S, E, Am);
                        end if;
                     end if;
                  end;
               when 2 =>
                  declare
                     ID : constant Positive := 1 + Next (Max_R);
                  begin
                     Delete_Reservation (Cal, Reservation_ID (ID));
                     Ref (ID).Active := False;
                  end;
               when 3 =>
                  declare
                     Shift : constant Natural := Next (Cap + 2);
                  begin
                     Move_Forward (Cal, Shift);
                     Start := Start + Time_Point (Shift);
                     for R of Ref loop
                        if R.Active and then R.E < Start then
                           R.Active := False;
                        elsif R.Active and then R.S < Start then
                           R.S := Start;
                        end if;
                     end loop;
                     Check (Get_Current_Start (Cal) = Start, "current start");
                  end;
               when others =>
                  Check (Query_Ranges (Cal, S, E) = Ref_Max (S, E),
                         "query" & Time_Point'Image (S) & Time_Point'Image (E)
                         & " got" & Resource_Amount'Image (Query_Ranges (Cal, S, E))
                         & " want" & Resource_Amount'Image (Ref_Max (S, E)));
                  Check (Check_Availability (Cal, S, E, Am, 15)
                         = (Ref_Max (S, E) + Am <= 15), "availability");
                  Check (not Check_Availability (Cal, Start + Time_Point (Cap), Start + Time_Point (Cap), 0, 100),
                         "availability outside the window");
            end case;
         end;
      end loop;
   end Run_Sequence;
begin
   for K in 1 .. 2_000 loop
      Run_Sequence (1 + Next (24), 1 + Next (12));
   end loop;
   --  Sizes above the old fixed 1000-slot arrays must work
   declare
      Cal : Calendar (2000, 1500);
      ID  : Reservation_ID;
      Ok  : Boolean;
   begin
      Initialize (Cal);
      Reserve (Cal, 0, 1999, 5, ID, Ok);
      Check (Ok and then Query_Ranges (Cal, 0, 1999) = 5, "capacity 2000");
      for K in 2 .. 1500 loop
         Reserve (Cal, Time_Point (K), Time_Point (K), 1, ID, Ok);
         Check (Ok, "1500 reservations");
      end loop;
      Check (Query_Ranges (Cal, 1400, 1400) = 6, "capacity 2000 query");
   exception
      when Constraint_Error =>
         Check (False, "capacity 2000 / 1500 reservations raised Constraint_Error");
   end;

   if Fails = 0 then
      Put_Line ("PASS Top_Nodes reference comparison (seed 20261009)");
   else
      Put_Line ("FAILED" & Natural'Image (Fails) & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Test_Reference;
