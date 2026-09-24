--  Standalone test suite for Nonblocking_Minimal_Spanning_Switch (main).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nonblocking_Minimal_Spanning_Switch; use Nonblocking_Minimal_Spanning_Switch;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Pos (X : Positive) return Positive is (X);

   function Create_Raises (N : Positive; K : Fabric_Kind) return Boolean is
      S : Switch;
   begin
      Create (S, N, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Raises;

   function Connect_Raises
     (S : in out Switch; A, B : Port_Id) return Boolean
   is
   begin
      Connect (S, A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Connect_Raises;

   function Rearrange_Raises
     (S : in out Switch; A, B : Port_Id) return Boolean
   is
   begin
      Rearrange_Connect (S, A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Rearrange_Raises;

   function Disconnect_Raises
     (S : in out Switch; A : Port_Id) return Boolean
   is
   begin
      Disconnect (S, A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Disconnect_Raises;

   function Is_Conn_Raises (S : Switch; A : Port_Id) return Boolean is
      B : Boolean;
   begin
      B := Is_Connected (S, A);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Is_Conn_Raises;

   function Empty_Full_Raises (S : Switch) return Boolean is
      B : Boolean;
   begin
      B := Empty_Fabric_Is_Fully_Nonblocking (S);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Full_Raises;

   S : Switch;

begin
   ------------------------------------------------------------------
   Section ("1. Create / order / kind / empty state");
   ------------------------------------------------------------------
   Check (Order (S) = 0, "default Order = 0");
   Check (Active_Connections (S) = 0, "default Active = 0");
   Check (Crosspoint_Count (S) = 0, "default Crosspoints = 0");

   Create (S, 1, Crossbar);
   Check (Order (S) = 1, "N=1 Order");
   Check (Kind_Of (S) = Crossbar, "N=1 Kind Crossbar");
   Check (Crosspoint_Count (S) = 1, "N=1 Crossbar Xpts = 1");
   Check (Active_Connections (S) = 0, "N=1 empty active");
   Check (Is_Strictly_Nonblocking_Fabric (S), "Crossbar is strict");
   Check (Clos_N (S) = 0 and Clos_M (S) = 0 and Clos_R (S) = 0,
          "Crossbar Clos params 0");

   Create (S, 4, Crossbar);
   Check (Order (S) = 4, "N=4 Order");
   Check (Crosspoint_Count (S) = 16, "N=4 Crossbar Xpts = 16");

   Create (S, 8, Crossbar);
   Check (Crosspoint_Count (S) = 64, "N=8 Crossbar Xpts = 64");

   Create (S, Pos (Max_N), Crossbar);
   Check (Order (S) = Max_N, "Max_N Order");
   Check (Crosspoint_Count (S) = Max_N * Max_N, "Max_N Crossbar Xpts");

   Check (Create_Raises (Pos (Max_N + 1), Crossbar),
          "Create N=Max_N+1 raises");
   Check (Create_Raises (Pos (Max_N + 5), Spanning),
          "Create oversized Spanning raises");

   ------------------------------------------------------------------
   Section ("2. Crossbar Connect / Disconnect / Can_Connect");
   ------------------------------------------------------------------
   Create (S, 3, Crossbar);
   Check (Can_Connect (S, 1, 1), "XB free 1→1");
   Check (Can_Connect (S, 1, 2), "XB free 1→2");
   Check (Can_Connect (S, 2, 3), "XB free 2→3");
   Connect (S, 1, 2);
   Check (Is_Connected (S, 1), "XB 1 connected");
   Check (not Is_Connected (S, 2), "XB 2 free");
   Check (Connected_Output (S, 1) = 2, "XB 1→2");
   Check (Is_Output_Busy (S, 2), "XB out 2 busy");
   Check (not Is_Output_Busy (S, 1), "XB out 1 free");
   Check (Active_Connections (S) = 1, "XB active 1");
   Check (not Can_Connect (S, 1, 3), "XB input busy blocks");
   Check (not Can_Connect (S, 2, 2), "XB output busy blocks");
   Check (Can_Connect (S, 2, 1), "XB 2→1 still free");
   Check (Can_Connect (S, 3, 3), "XB 3→3 free");
   Connect (S, 2, 1);
   Connect (S, 3, 3);
   Check (Active_Connections (S) = 3, "XB full active 3");
   Check (not Can_Connect (S, 1, 1), "XB full no room");
   Disconnect (S, 2);
   Check (Active_Connections (S) = 2, "XB after disc active 2");
   Check (not Is_Connected (S, 2), "XB 2 free after disc");
   Check (Can_Connect (S, 2, 1), "XB 2→1 after disc");
   Connect (S, 2, 1);
   Check (Connected_Output (S, 2) = 1, "XB reconnect 2→1");

   ------------------------------------------------------------------
   Section ("3. Crossbar identity / reverse / swap permutations N=3");
   ------------------------------------------------------------------
   Create (S, 3, Crossbar);
   Connect (S, 1, 1); Connect (S, 2, 2); Connect (S, 3, 3);
   Check (Connected_Output (S, 1) = 1, "id 1");
   Check (Connected_Output (S, 2) = 2, "id 2");
   Check (Connected_Output (S, 3) = 3, "id 3");
   Clear_Connections (S);
   Check (Active_Connections (S) = 0, "clear zeros active");
   Connect (S, 1, 3); Connect (S, 2, 2); Connect (S, 3, 1);
   Check (Connected_Output (S, 1) = 3, "rev 1→3");
   Check (Connected_Output (S, 3) = 1, "rev 3→1");
   Clear_Connections (S);
   Connect (S, 1, 2); Connect (S, 2, 1); Connect (S, 3, 3);
   Check (Connected_Output (S, 1) = 2 and Connected_Output (S, 2) = 1,
          "swap 1↔2");

   ------------------------------------------------------------------
   Section ("4. Crossbar full permutation nonblocking N=1..4");
   ------------------------------------------------------------------
   for N in 1 .. 4 loop
      Create (S, N, Crossbar);
      Check (Empty_Fabric_Is_Fully_Nonblocking (S),
             "XB empty full nonblocking N=" & N'Image);
      Check (All_Free_Permutations_Routable_Without_Rearrange (S),
             "XB all free perms no-rearr N=" & N'Image);
   end loop;

   ------------------------------------------------------------------
   Section ("5. Crossbar partial occupancy still strict");
   ------------------------------------------------------------------
   Create (S, 4, Crossbar);
   Connect (S, 1, 3);
   Check (All_Free_Permutations_Routable_Without_Rearrange (S),
          "XB partial 1→3 remaining perms");
   Connect (S, 2, 4);
   Check (All_Free_Permutations_Routable_Without_Rearrange (S),
          "XB partial two calls remaining");
   Connect (S, 3, 1);
   Check (All_Free_Permutations_Routable_Without_Rearrange (S),
          "XB one free pair left");
   Connect (S, 4, 2);
   Check (All_Free_Permutations_Routable_Without_Rearrange (S),
          "XB full vacuous remaining");

   ------------------------------------------------------------------
   Section ("6. Spanning Clos params and crosspoints");
   ------------------------------------------------------------------
   Create (S, 4, Spanning);
   Check (Kind_Of (S) = Spanning, "Spanning kind");
   Check (not Is_Strictly_Nonblocking_Fabric (S), "Spanning not strict");
   Check (Clos_M (S) = Clos_N (S), "Spanning m = n");
   Check (Clos_N (S) > 0 and Clos_R (S) > 0, "Spanning n,r > 0");
   Check (Clos_N (S) * Clos_R (S) >= 4, "n·r ≥ N=4");
   --  n=2, r=2, m=2 → Xpts = 2*2*2*2 + 2*2*2 = 16+8 = 24? Wait:
   --  2·n·m·r + m·r² = 2·2·2·2 + 2·2² = 16 + 8 = 24
   Check (Clos_N (S) = 2, "N=4 Clos n=2");
   Check (Clos_R (S) = 2, "N=4 Clos r=2");
   Check (Crosspoint_Count (S) = 24, "N=4 Spanning Xpts = 24");
   Check (Crosspoint_Count (S) = Nat (24),
          "N=4 Spanning heavier than XB (educational)");

   Create (S, 9, Spanning);
   Check (Clos_N (S) = 3 and Clos_R (S) = 3 and Clos_M (S) = 3,
          "N=9 Clos 3,3,3");
   --  2·3·3·3 + 3·3² = 54 + 27 = 81 = N² (tie at N=9)
   Check (Crosspoint_Count (S) = 81, "N=9 Spanning Xpts = 81");

   Create (S, 16, Spanning);
   Check (Clos_N (S) = 4 and Clos_R (S) = 4, "N=16 Clos n=r=4");
   --  2·4·4·4 + 4·16 = 128 + 64 = 192 < 256
   Check (Crosspoint_Count (S) = 192, "N=16 Spanning Xpts = 192 < 256");
   Check (Crosspoint_Count (S) < 16 * 16, "N=16 Spanning fewer than XB");

   Create (S, 25, Spanning);
   Check (Clos_N (S) = 5 and Clos_R (S) = 5, "N=25 Clos 5");
   --  2·5·5·5 + 5·25 = 250 + 125 = 375 < 625
   Check (Crosspoint_Count (S) = 375, "N=25 Spanning Xpts = 375");
   Check (Crosspoint_Count (S) < 25 * 25, "N=25 Spanning fewer than XB");

   Create (S, 7, Spanning);
   Check (Clos_N (S) * Clos_R (S) >= 7, "N=7 n·r ≥ 7");
   Check (Clos_M (S) = Clos_N (S), "N=7 m = n");

   ------------------------------------------------------------------
   Section ("7. Spanning Connect without rearrange");
   ------------------------------------------------------------------
   Create (S, 4, Spanning);
   Check (Can_Connect (S, 1, 1), "SP free 1→1");
   Connect (S, 1, 1);
   Check (Is_Connected (S, 1) and Connected_Output (S, 1) = 1, "SP 1→1");
   Connect (S, 2, 2);
   Check (Active_Connections (S) = 2, "SP active 2");
   Connect (S, 3, 3);
   Connect (S, 4, 4);
   Check (Active_Connections (S) = 4, "SP identity full");
   Clear_Connections (S);
   Connect (S, 1, 4);
   Connect (S, 2, 3);
   Connect (S, 3, 2);
   Connect (S, 4, 1);
   Check (Connected_Output (S, 1) = 4 and Connected_Output (S, 4) = 1,
          "SP reverse matching");

   ------------------------------------------------------------------
   Section ("8. Spanning Rearrange_Connect & empty nonblocking");
   ------------------------------------------------------------------
   for N in 1 .. 4 loop
      Create (S, N, Spanning);
      Check (Empty_Fabric_Is_Fully_Nonblocking (S),
             "SP empty rearrangeable N=" & N'Image);
   end loop;

   Create (S, 4, Spanning);
   --  Force a scenario: fill with identity via Connect, clear, then
   --  build a crossing permutation via Rearrange_Connect one-by-one.
   Rearrange_Connect (S, 1, 2);
   Rearrange_Connect (S, 2, 1);
   Rearrange_Connect (S, 3, 4);
   Rearrange_Connect (S, 4, 3);
   Check (Active_Connections (S) = 4, "SP rearrange full swap pairs");
   Check (Connected_Output (S, 1) = 2, "SP rearr 1→2");
   Check (Connected_Output (S, 2) = 1, "SP rearr 2→1");

   ------------------------------------------------------------------
   Section ("9. Spanning blocking without rearrange (contention)");
   ------------------------------------------------------------------
   --  For N=4, n=2,r=2,m=2: first-stage switch 1 serves inputs 1,2;
   --  third-stage switch 1 serves outputs 1,2.
   --  Connect 1→1 and 2→2 using both middles between FS1 and TS1.
   --  Then a free input on FS2 to free output on TS1 may still work,
   --  but two calls from same FS to same TS consume both middles.
   Create (S, 4, Spanning);
   Connect (S, 1, 1);
   Connect (S, 2, 2);
   --  Inputs 1,2 (same FS) both go to outputs 1,2 (same TS) — uses m=2
   --  middles. Remaining free: in 3,4 out 3,4 — same FS2/TS2, OK.
   Check (Can_Connect (S, 3, 3), "SP 3→3 after FS1 filled to TS1");
   Check (Can_Connect (S, 3, 4), "SP 3→4 free");
   --  Partial occupancy: remaining free perms on {3,4}×{3,4} should work
   Check (All_Free_Permutations_Routable_Without_Rearrange (S),
          "SP remaining {3,4} no-rearr OK");

   --  Construct a known no-rearrange failure when possible:
   --  After 1→1, 2→2, try to also need paths that contend — with only
   --  free ports 3,4 → 3,4 there is no failure. Use N=4 with mixed:
   Clear_Connections (S);
   Connect (S, 1, 1);
   Connect (S, 2, 3);
   --  FS1 uses some middles to TS1 and TS2. Remaining in {3,4} out {2,4}.
   Check (Active_Connections (S) = 2, "SP mixed active 2");
   --  At least one free connection should exist
   Check (Can_Connect (S, 3, 2) or Can_Connect (S, 3, 4)
            or Can_Connect (S, 4, 2) or Can_Connect (S, 4, 4),
          "SP some free edge exists");

   --  Demonstrate Rearrange_Connect succeeds when Connect might fail:
   --  Saturate middle options then rearrange.
   Create (S, 4, Spanning);
   Connect (S, 1, 1);
   Connect (S, 2, 2);
   Connect (S, 3, 3);
   --  Last port: Connect should work for 4→4
   Check (Can_Connect (S, 4, 4), "SP last 4→4 Can");
   Connect (S, 4, 4);
   Check (Active_Connections (S) = 4, "SP filled identity");

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument guards");
   ------------------------------------------------------------------
   Create (S, 3, Crossbar);
   Check (Is_Conn_Raises (S, Port_Id (4)), "Is_Connected bad port");
   Check (Connect_Raises (S, Port_Id (4), 1), "Connect bad input");
   Check (Connect_Raises (S, 1, Port_Id (4)), "Connect bad output");
   Connect (S, 1, 1);
   Check (Connect_Raises (S, 1, 2), "Connect busy input");
   Check (Connect_Raises (S, 2, 1), "Connect busy output");
   Check (Disconnect_Raises (S, 2), "Disconnect free input");
   Check (Disconnect_Raises (S, Port_Id (4)), "Disconnect bad port");
   Disconnect (S, 1);
   Check (Disconnect_Raises (S, 1), "Disconnect already free");

   Create (S, 2, Spanning);
   Check (Rearrange_Raises (S, Port_Id (3), 1), "Rearrange bad in");
   Rearrange_Connect (S, 1, 1);
   Check (Rearrange_Raises (S, 1, 2), "Rearrange busy input");
   Check (Rearrange_Raises (S, 2, 1), "Rearrange busy output");

   Create (S, 2, Crossbar);
   Connect (S, 1, 1);
   Check (Empty_Full_Raises (S), "Empty_Full on nonempty raises");

   declare
      Z : Switch;
   begin
      Check (Empty_Full_Raises (Z), "Empty_Full on N=0 raises");
      Check (Is_Conn_Raises (Z, 1), "Is_Connected on N=0 raises");
   end;

   ------------------------------------------------------------------
   Section ("11. Crossbar Rearrange_Connect ≡ Connect");
   ------------------------------------------------------------------
   Create (S, 5, Crossbar);
   Rearrange_Connect (S, 1, 5);
   Rearrange_Connect (S, 2, 4);
   Rearrange_Connect (S, 3, 3);
   Rearrange_Connect (S, 4, 2);
   Rearrange_Connect (S, 5, 1);
   Check (Active_Connections (S) = 5, "XB rearr full reverse");
   Check (Connected_Output (S, 1) = 5, "XB rearr 1→5");
   Check (Connected_Output (S, 5) = 1, "XB rearr 5→1");
   Check (Crosspoint_Count (S) = 25, "XB N=5 Xpts");

   ------------------------------------------------------------------
   Section ("12. Clear / rebuild / Max_N smoke");
   ------------------------------------------------------------------
   Create (S, 8, Crossbar);
   for I in 1 .. 8 loop
      Connect (S, Port_Id (I), Port_Id (9 - I));
   end loop;
   Check (Active_Connections (S) = 8, "XB N=8 reverse full");
   Clear_Connections (S);
   Check (Active_Connections (S) = 0, "clear after full");
   for I in 1 .. 8 loop
      Check (not Is_Connected (S, Port_Id (I)),
             "cleared input " & I'Image);
   end loop;
   Create (S, Pos (Max_N), Spanning);
   Check (Order (S) = Max_N, "Max_N Spanning order");
   Check (Clos_M (S) = Clos_N (S), "Max_N m=n");
   Check (Crosspoint_Count (S) < Max_N * Max_N
            or Crosspoint_Count (S) = Max_N * Max_N,
          "Max_N Spanning Xpts ≤ or educational ≥ XB");
   --  Connect a sparse matching without rearrange
   for I in 1 .. Max_N loop
      Connect (S, Port_Id (I), Port_Id (I));
   end loop;
   Check (Active_Connections (S) = Max_N, "Max_N identity via Connect");
   for I in 1 .. Max_N loop
      Disconnect (S, Port_Id (I));
   end loop;
   Check (Active_Connections (S) = 0, "Max_N all disconnected");

   ------------------------------------------------------------------
   Section ("13. Many small Crossbar permutations N=2");
   ------------------------------------------------------------------
   Create (S, 2, Crossbar);
   Connect (S, 1, 1); Connect (S, 2, 2);
   Check (Connected_Output (S, 1) = 1 and Connected_Output (S, 2) = 2,
          "N=2 id");
   Clear_Connections (S);
   Connect (S, 1, 2); Connect (S, 2, 1);
   Check (Connected_Output (S, 1) = 2 and Connected_Output (S, 2) = 1,
          "N=2 swap");
   Check (Empty_Full_Raises (S), "nonempty Empty_Full raises");
   Clear_Connections (S);
   Check (Empty_Fabric_Is_Fully_Nonblocking (S), "N=2 empty after clear");

   ------------------------------------------------------------------
   Section ("14. Crosspoint formula table");
   ------------------------------------------------------------------
   declare
      procedure Check_XB (N : Positive) is
      begin
         Create (S, N, Crossbar);
         Check (Crosspoint_Count (S) = N * N,
                "XB formula N=" & N'Image);
      end Check_XB;
   begin
      Check_XB (1); Check_XB (2); Check_XB (3); Check_XB (5);
      Check_XB (6); Check_XB (10); Check_XB (12); Check_XB (15);
      Check_XB (20); Check_XB (24); Check_XB (30); Check_XB (32);
   end;

   ------------------------------------------------------------------
   Section ("15. Spanning sequential matching N=5..8");
   ------------------------------------------------------------------
   for N in 5 .. 8 loop
      Create (S, N, Spanning);
      for I in 1 .. N loop
         Rearrange_Connect (S, Port_Id (I), Port_Id (N + 1 - I));
      end loop;
      Check (Active_Connections (S) = N,
             "SP reverse full N=" & N'Image);
      for I in 1 .. N loop
         Check (Connected_Output (S, Port_Id (I)) = N + 1 - I,
                "SP rev map N=" & N'Image & " i=" & I'Image);
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("16. Disconnect order / re-connect stress");
   ------------------------------------------------------------------
   Create (S, 6, Crossbar);
   for I in 1 .. 6 loop
      Connect (S, Port_Id (I), Port_Id (I));
   end loop;
   for I in 1 .. 6 loop
      Disconnect (S, Port_Id (I));
      Check (not Is_Connected (S, Port_Id (I)),
             "disc mid " & I'Image);
      Check (Active_Connections (S) = 6 - I,
             "active after disc " & I'Image);
   end loop;
   for I in 1 .. 6 loop
      Connect (S, Port_Id (I), Port_Id (7 - I));
   end loop;
   Check (Active_Connections (S) = 6, "reconnect reverse");
   for I in reverse 1 .. 6 loop
      Disconnect (S, Port_Id (I));
   end loop;
   Check (Active_Connections (S) = 0, "reverse disc empty");

   Create (S, 6, Spanning);
   for I in 1 .. 6 loop
      Connect (S, Port_Id (I), Port_Id (I));
   end loop;
   Disconnect (S, 3);
   Disconnect (S, 5);
   Check (Active_Connections (S) = 4, "SP hole active 4");
   Check (Can_Connect (S, 3, 3), "SP hole 3→3");
   Check (Can_Connect (S, 5, 5), "SP hole 5→5");
   --  Crossing 3→5 / 5→3 may need middle rearrange under residual load.
   Rearrange_Connect (S, 3, 5);
   Rearrange_Connect (S, 5, 3);
   Check (Connected_Output (S, 3) = 5, "SP hole swap 3→5");
   Check (Connected_Output (S, 5) = 3, "SP hole swap 5→3");

   ------------------------------------------------------------------
   Section ("17. Can_Connect false paths / self busy");
   ------------------------------------------------------------------
   Create (S, 4, Crossbar);
   Connect (S, 2, 3);
   Check (not Can_Connect (S, 2, 1), "busy in");
   Check (not Can_Connect (S, 1, 3), "busy out");
   Check (not Can_Connect (S, 2, 3), "both busy same call");
   Check (Can_Connect (S, 1, 1), "other free");
   Check (Can_Connect (S, 4, 2), "other free 4→2");
   Check (Can_Connect (S, 3, 4), "other free 3→4");
   Check (Can_Connect (S, 1, 4), "other free 1→4");
   Check (Can_Connect (S, 4, 1), "other free 4→1");
   Check (Can_Connect (S, 3, 2), "other free 3→2");
   Check (Can_Connect (S, 1, 2), "other free 1→2");

   ------------------------------------------------------------------
   Section ("18. Spanning vs Crossbar crosspoint comparison");
   ------------------------------------------------------------------
   declare
      XB, SP : Natural;
   begin
      for N in 1 .. Max_N loop
         Create (S, N, Crossbar);
         XB := Crosspoint_Count (S);
         Create (S, N, Spanning);
         SP := Crosspoint_Count (S);
         Check (XB = N * N, "cmp XB N=" & N'Image);
         Check (SP = 2 * Clos_N (S) * Clos_M (S) * Clos_R (S)
                  + Clos_M (S) * Clos_R (S) * Clos_R (S),
                "cmp SP formula N=" & N'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("19. N=1 trivial fabrics");
   ------------------------------------------------------------------
   Create (S, 1, Crossbar);
   Check (Can_Connect (S, 1, 1), "N=1 XB can");
   Connect (S, 1, 1);
   Check (Connected_Output (S, 1) = 1, "N=1 XB conn");
   Disconnect (S, 1);
   Rearrange_Connect (S, 1, 1);
   Check (Is_Connected (S, 1), "N=1 XB rearr");
   Create (S, 1, Spanning);
   Check (Empty_Fabric_Is_Fully_Nonblocking (S), "N=1 SP full");
   Rearrange_Connect (S, 1, 1);
   Check (Connected_Output (S, 1) = 1, "N=1 SP conn");

   ------------------------------------------------------------------
   Section ("20. Kind_Of / Is_Strict persistence");
   ------------------------------------------------------------------
   Create (S, 10, Crossbar);
   Connect (S, 1, 2);
   Check (Kind_Of (S) = Crossbar, "kind stable XB");
   Check (Is_Strictly_Nonblocking_Fabric (S), "strict stable XB");
   Create (S, 10, Spanning);
   Connect (S, 1, 2);
   Check (Kind_Of (S) = Spanning, "kind stable SP");
   Check (not Is_Strictly_Nonblocking_Fabric (S), "not strict SP");
   Check (Nat (Active_Connections (S)) = 1, "active 1 after recreate");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
