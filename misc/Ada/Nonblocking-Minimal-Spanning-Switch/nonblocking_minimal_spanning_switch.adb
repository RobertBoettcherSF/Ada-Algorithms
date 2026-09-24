--  Nonblocking_Minimal_Spanning_Switch body — crossbar + Clos spanning fabric.

pragma Ada_2022;

package body Nonblocking_Minimal_Spanning_Switch
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Clos parameter selection (educational)
   -------------------------------------------------------------------------

   procedure Choose_Clos_Params
     (Order_N : Positive; Out_N, Out_M, Out_R : out Natural)
   is
      Cand : Natural;
   begin
      --  Prefer n ≈ √N so that n·r ≥ N with r = ⌈N/n⌉ and m = n
      --  (rearrangeably nonblocking Clos).
      Cand := 1;
      while Cand * Cand < Order_N loop
         Cand := Cand + 1;
      end loop;
      Out_N := Cand;
      Out_R := (Order_N + Out_N - 1) / Out_N;
      Out_M := Out_N;
   end Choose_Clos_Params;

   function Crosspoints_For
     (Kind : Fabric_Kind; Order_N, Cn, Cm, Cr : Natural) return Natural
   is
   begin
      case Kind is
         when Crossbar =>
            return Order_N * Order_N;
         when Spanning =>
            --  r·(n×m) + m·(r×r) + r·(m×n) = 2·n·m·r + m·r²
            return 2 * Cn * Cm * Cr + Cm * Cr * Cr;
      end case;
   end Crosspoints_For;

   -------------------------------------------------------------------------
   -- Validation
   -------------------------------------------------------------------------

   procedure Validate_Port (S : Switch; P : Port_Id) is
   begin
      if S.N = 0 or else Natural (P) > S.N then
         raise Invalid_Argument;
      end if;
   end Validate_Port;

   procedure Validate_Two (S : Switch; A, B : Port_Id) is
   begin
      Validate_Port (S, A);
      Validate_Port (S, B);
   end Validate_Two;

   -------------------------------------------------------------------------
   -- Stage mapping (Spanning)
   -------------------------------------------------------------------------

   function First_Stage_Of (S : Switch; Input : Port_Id) return Positive is
   begin
      return (Natural (Input) - 1) / S.CN + 1;
   end First_Stage_Of;

   function Third_Stage_Of (S : Switch; Output : Port_Id) return Positive is
   begin
      return (Natural (Output) - 1) / S.CN + 1;
   end Third_Stage_Of;

   -------------------------------------------------------------------------
   -- Low-level link helpers (Spanning)
   -------------------------------------------------------------------------

   procedure Clear_Links (S : in out Switch) is
   begin
      for I in 1 .. Max_N loop
         for J in 1 .. Max_N loop
            S.FS_Mid (I, J) := False;
            S.Mid_TS (I, J) := False;
         end loop;
      end loop;
      for P in Port_Id loop
         S.Mid_Of (P) := 0;
      end loop;
   end Clear_Links;

   function Middle_Free_For
     (S : Switch; Input, Output : Port_Id; Mid : Positive) return Boolean
   is
      FS : constant Positive := First_Stage_Of (S, Input);
      TS : constant Positive := Third_Stage_Of (S, Output);
   begin
      return not S.FS_Mid (FS, Mid) and then not S.Mid_TS (Mid, TS);
   end Middle_Free_For;

   function Find_Free_Middle
     (S : Switch; Input, Output : Port_Id) return Natural
   is
   begin
      for Mid in 1 .. S.CM loop
         if Middle_Free_For (S, Input, Output, Mid) then
            return Mid;
         end if;
      end loop;
      return 0;
   end Find_Free_Middle;

   procedure Assign_Middle
     (S : in out Switch; Input, Output : Port_Id; Mid : Positive)
   is
      FS : constant Positive := First_Stage_Of (S, Input);
      TS : constant Positive := Third_Stage_Of (S, Output);
   begin
      S.FS_Mid (FS, Mid) := True;
      S.Mid_TS (Mid, TS) := True;
      S.Mid_Of (Input) := Middle_Index (Mid);
   end Assign_Middle;

   procedure Release_Middle (S : in out Switch; Input : Port_Id) is
      Mid : constant Natural := Natural (S.Mid_Of (Input));
      Outp : constant Natural := S.Out_Of (Input);
      FS   : Positive;
      TS   : Positive;
   begin
      if Mid = 0 or else Outp = 0 then
         S.Mid_Of (Input) := 0;
         return;
      end if;
      FS := First_Stage_Of (S, Input);
      TS := Third_Stage_Of (S, Port_Id (Outp));
      S.FS_Mid (FS, Mid) := False;
      S.Mid_TS (Mid, TS) := False;
      S.Mid_Of (Input) := 0;
   end Release_Middle;

   -------------------------------------------------------------------------
   -- Create / queries
   -------------------------------------------------------------------------

   procedure Create
     (S : in out Switch; N : Positive; Kind : Fabric_Kind := Crossbar)
   is
      Pn, Pm, Pr : Natural;
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      S.N := N;
      S.Kind := Kind;
      S.Active := 0;
      for P in Port_Id loop
         S.Out_Of (P) := 0;
         S.In_Of (P) := 0;
         S.Mid_Of (P) := 0;
      end loop;
      Clear_Links (S);
      if Kind = Spanning then
         Choose_Clos_Params (N, Pn, Pm, Pr);
         S.CN := Pn;
         S.CM := Pm;
         S.CR := Pr;
      else
         S.CN := 0;
         S.CM := 0;
         S.CR := 0;
      end if;
   end Create;

   function Order (S : Switch) return Natural is
   begin
      return S.N;
   end Order;

   function Kind_Of (S : Switch) return Fabric_Kind is
   begin
      return S.Kind;
   end Kind_Of;

   function Crosspoint_Count (S : Switch) return Natural is
   begin
      if S.N = 0 then
         return 0;
      end if;
      return Crosspoints_For (S.Kind, S.N, S.CN, S.CM, S.CR);
   end Crosspoint_Count;

   function Active_Connections (S : Switch) return Natural is
   begin
      return S.Active;
   end Active_Connections;

   function Clos_N (S : Switch) return Natural is (S.CN);
   function Clos_M (S : Switch) return Natural is (S.CM);
   function Clos_R (S : Switch) return Natural is (S.CR);

   function Is_Strictly_Nonblocking_Fabric (S : Switch) return Boolean is
   begin
      return S.Kind = Crossbar;
   end Is_Strictly_Nonblocking_Fabric;

   -------------------------------------------------------------------------
   -- Port status
   -------------------------------------------------------------------------

   function Is_Connected (S : Switch; Input : Port_Id) return Boolean is
   begin
      Validate_Port (S, Input);
      return S.Out_Of (Input) /= 0;
   end Is_Connected;

   function Is_Output_Busy (S : Switch; Output : Port_Id) return Boolean is
   begin
      Validate_Port (S, Output);
      return S.In_Of (Output) /= 0;
   end Is_Output_Busy;

   function Connected_Output (S : Switch; Input : Port_Id) return Natural is
   begin
      Validate_Port (S, Input);
      return S.Out_Of (Input);
   end Connected_Output;

   -------------------------------------------------------------------------
   -- Can_Connect / Connect / Disconnect
   -------------------------------------------------------------------------

   function Can_Connect
     (S : Switch; Input, Output : Port_Id) return Boolean
   is
   begin
      Validate_Two (S, Input, Output);
      if S.Out_Of (Input) /= 0 or else S.In_Of (Output) /= 0 then
         return False;
      end if;
      case S.Kind is
         when Crossbar =>
            return True;
         when Spanning =>
            return Find_Free_Middle (S, Input, Output) /= 0;
      end case;
   end Can_Connect;

   procedure Connect
     (S : in out Switch; Input, Output : Port_Id)
   is
      Mid : Natural;
   begin
      if not Can_Connect (S, Input, Output) then
         raise Invalid_Argument;
      end if;
      case S.Kind is
         when Crossbar =>
            null;
         when Spanning =>
            Mid := Find_Free_Middle (S, Input, Output);
            Assign_Middle (S, Input, Output, Mid);
      end case;
      S.Out_Of (Input) := Natural (Output);
      S.In_Of (Output) := Natural (Input);
      S.Active := S.Active + 1;
   end Connect;

   procedure Disconnect (S : in out Switch; Input : Port_Id) is
      Outp : Natural;
   begin
      Validate_Port (S, Input);
      Outp := S.Out_Of (Input);
      if Outp = 0 then
         raise Invalid_Argument;
      end if;
      if S.Kind = Spanning then
         Release_Middle (S, Input);
      end if;
      S.Out_Of (Input) := 0;
      S.In_Of (Port_Id (Outp)) := 0;
      S.Active := S.Active - 1;
   end Disconnect;

   procedure Clear_Connections (S : in out Switch) is
   begin
      for P in Port_Id loop
         S.Out_Of (P) := 0;
         S.In_Of (P) := 0;
         S.Mid_Of (P) := 0;
      end loop;
      Clear_Links (S);
      S.Active := 0;
   end Clear_Connections;

   -------------------------------------------------------------------------
   -- Rearrange: re-route a full matching on Spanning via backtracking
   -------------------------------------------------------------------------

   type Pair_Rec is record
      Input  : Port_Id;
      Output : Port_Id;
   end record;

   type Pair_List is array (1 .. Max_N) of Pair_Rec;

   --  Attempt to assign middle switches for Pairs (1 .. Count) given
   --  current link occupancy in S. Mutates S.FS_Mid / Mid_TS / Mid_Of.
   function Route_Matching
     (S : in out Switch; Pairs : Pair_List; Count : Natural) return Boolean
   is
      function Recurse (Index : Natural) return Boolean is
         Inp : Port_Id;
         Outp : Port_Id;
      begin
         if Index > Count then
            return True;
         end if;
         Inp := Pairs (Index).Input;
         Outp := Pairs (Index).Output;
         for Mid in 1 .. S.CM loop
            if Middle_Free_For (S, Inp, Outp, Mid) then
               Assign_Middle (S, Inp, Outp, Mid);
               if Recurse (Index + 1) then
                  return True;
               end if;
               --  undo
               declare
                  FS : constant Positive := First_Stage_Of (S, Inp);
                  TS : constant Positive := Third_Stage_Of (S, Outp);
               begin
                  S.FS_Mid (FS, Mid) := False;
                  S.Mid_TS (Mid, TS) := False;
                  S.Mid_Of (Inp) := 0;
               end;
            end if;
         end loop;
         return False;
      end Recurse;
   begin
      --  Clear only middle links; logical Out_Of/In_Of already set by caller
      Clear_Links (S);
      return Recurse (1);
   end Route_Matching;

   procedure Rearrange_Connect
     (S : in out Switch; Input, Output : Port_Id)
   is
      Pairs : Pair_List;
      Count : Natural := 0;
      Ok    : Boolean;
   begin
      Validate_Two (S, Input, Output);
      if S.Out_Of (Input) /= 0 or else S.In_Of (Output) /= 0 then
         raise Invalid_Argument;
      end if;

      case S.Kind is
         when Crossbar =>
            --  Strict fabric: rearrange not needed; same as Connect.
            Connect (S, Input, Output);
            return;
         when Spanning =>
            null;
      end case;

      --  Collect existing calls + the new request.
      for P in 1 .. S.N loop
         if S.Out_Of (Port_Id (P)) /= 0 then
            Count := Count + 1;
            Pairs (Count) :=
              (Input  => Port_Id (P),
               Output => Port_Id (S.Out_Of (Port_Id (P))));
         end if;
      end loop;
      Count := Count + 1;
      Pairs (Count) := (Input => Input, Output => Output);

      --  Tentatively record the logical matching.
      S.Out_Of (Input) := Natural (Output);
      S.In_Of (Output) := Natural (Input);
      S.Active := S.Active + 1;

      Ok := Route_Matching (S, Pairs, Count);
      if not Ok then
         --  Should not happen for m = n rearrangeable Clos on a matching;
         --  treat as Invalid_Argument to surface educational bugs.
         S.Out_Of (Input) := 0;
         S.In_Of (Output) := 0;
         S.Active := S.Active - 1;
         Clear_Links (S);
         --  Restore previous middle routes for remaining calls.
         declare
            Old_Count : Natural := 0;
            Old_Pairs : Pair_List;
            Restored  : Boolean;
         begin
            for P in 1 .. S.N loop
               if S.Out_Of (Port_Id (P)) /= 0 then
                  Old_Count := Old_Count + 1;
                  Old_Pairs (Old_Count) :=
                    (Input  => Port_Id (P),
                     Output => Port_Id (S.Out_Of (Port_Id (P))));
               end if;
            end loop;
            Restored := Route_Matching (S, Old_Pairs, Old_Count);
            pragma Unreferenced (Restored);
         end;
         raise Invalid_Argument;
      end if;
   end Rearrange_Connect;

   -------------------------------------------------------------------------
   -- Permutation enumeration helpers
   -------------------------------------------------------------------------

   procedure Swap_Nat (A, B : in out Natural) is
      T : constant Natural := A;
   begin
      A := B;
      B := T;
   end Swap_Nat;

   function All_Free_Permutations_Routable_Without_Rearrange
     (S : Switch) return Boolean
   is
      Free_In  : array (1 .. Max_N) of Port_Id;
      Free_Out : array (1 .. Max_N) of Natural;
      K        : Natural := 0;
      --  Snapshot of S is immutable here; we mutate a local copy.
      Local    : Switch := S;
      Ok       : Boolean := True;

      procedure Try_Perms (Depth : Natural) is
         Saved_Active : Natural;
         Saved_Out    : Out_Map;
         Saved_In     : In_Map;
         Saved_Mid    : Middle_Of_Input;
         Saved_FS     : Link_RM;
         Saved_TS     : Link_RM;
      begin
         if not Ok then
            return;
         end if;
         if Depth > K then
            return;
         end if;
         --  Assign Free_In(Depth) → some remaining Free_Out(j), j ≥ Depth
         for J in Depth .. K loop
            Swap_Nat (Free_Out (Depth), Free_Out (J));
            declare
               Inp  : constant Port_Id := Free_In (Depth);
               Outp : constant Port_Id := Port_Id (Free_Out (Depth));
            begin
               if not Can_Connect (Local, Inp, Outp) then
                  Ok := False;
                  Swap_Nat (Free_Out (Depth), Free_Out (J));
                  return;
               end if;
               --  Save and connect
               Saved_Active := Local.Active;
               Saved_Out := Local.Out_Of;
               Saved_In := Local.In_Of;
               Saved_Mid := Local.Mid_Of;
               Saved_FS := Local.FS_Mid;
               Saved_TS := Local.Mid_TS;
               Connect (Local, Inp, Outp);
               if Depth = K then
                  null;  -- full bijection succeeded under no-rearrange
               else
                  Try_Perms (Depth + 1);
               end if;
               --  Restore snapshot (backtrack)
               Local.Active := Saved_Active;
               Local.Out_Of := Saved_Out;
               Local.In_Of := Saved_In;
               Local.Mid_Of := Saved_Mid;
               Local.FS_Mid := Saved_FS;
               Local.Mid_TS := Saved_TS;
            end;
            Swap_Nat (Free_Out (Depth), Free_Out (J));
            if not Ok then
               return;
            end if;
         end loop;
      end Try_Perms;

   begin
      if S.N = 0 then
         return True;
      end if;
      for P in 1 .. S.N loop
         if S.Out_Of (Port_Id (P)) = 0 then
            K := K + 1;
            Free_In (K) := Port_Id (P);
         end if;
      end loop;
      declare
         Ko : Natural := 0;
      begin
         for P in 1 .. S.N loop
            if S.In_Of (Port_Id (P)) = 0 then
               Ko := Ko + 1;
               Free_Out (Ko) := P;
            end if;
         end loop;
         if Ko /= K then
            return False;  -- inconsistent fabric
         end if;
      end;
      if K = 0 then
         return True;
      end if;
      Try_Perms (1);
      return Ok;
   end All_Free_Permutations_Routable_Without_Rearrange;

   function Empty_Fabric_Is_Fully_Nonblocking (S : Switch) return Boolean is
      Local : Switch := S;
      Perm  : array (1 .. Max_N) of Natural;
      Ok    : Boolean := True;

      procedure Try_Perms (Depth : Natural) is
      begin
         if not Ok then
            return;
         end if;
         if Depth > Local.N then
            --  Apply full permutation via appropriate connect API
            Clear_Connections (Local);
            for I in 1 .. Local.N loop
               declare
                  Inp  : constant Port_Id := Port_Id (I);
                  Outp : constant Port_Id := Port_Id (Perm (I));
               begin
                  case Local.Kind is
                     when Crossbar =>
                        if not Can_Connect (Local, Inp, Outp) then
                           Ok := False;
                           return;
                        end if;
                        Connect (Local, Inp, Outp);
                     when Spanning =>
                        begin
                           Rearrange_Connect (Local, Inp, Outp);
                        exception
                           when Invalid_Argument =>
                              Ok := False;
                              return;
                        end;
                  end case;
               end;
            end loop;
            return;
         end if;
         for J in Depth .. Local.N loop
            Swap_Nat (Perm (Depth), Perm (J));
            Try_Perms (Depth + 1);
            Swap_Nat (Perm (Depth), Perm (J));
            if not Ok then
               return;
            end if;
         end loop;
      end Try_Perms;

   begin
      if S.N = 0 then
         raise Invalid_Argument;
      end if;
      if S.Active /= 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. S.N loop
         Perm (I) := I;
      end loop;
      Try_Perms (1);
      return Ok;
   end Empty_Fabric_Is_Fully_Nonblocking;

end Nonblocking_Minimal_Spanning_Switch;
