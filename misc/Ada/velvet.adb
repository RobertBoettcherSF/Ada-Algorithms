--  Velvet — package body (educational de Bruijn short-read assembler).

pragma Ada_2022;

package body Velvet
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Upper (C : Character) return Character is
   begin
      if C in 'a' .. 'z' then
         return Character'Val (Character'Pos (C) - 32);
      end if;
      return C;
   end Upper;

   function Node_Key (N : Node_Record) return String is
   begin
      return N.Seq (1 .. N.Len);
   end Node_Key;

   function Find_Node (G : Graph; Seq : String) return Node_Index is
   begin
      for I in 1 .. G.N_Nodes loop
         if G.Nodes (I).Alive
           and then G.Nodes (I).Len = Seq'Length
           and then G.Nodes (I).Seq (1 .. Seq'Length) = Seq
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Node;

   procedure Recompute_Degrees (G : in out Graph) is
   begin
      for I in 1 .. G.N_Nodes loop
         G.Nodes (I).In_Deg := 0;
         G.Nodes (I).Out_Deg := 0;
      end loop;
      for E in 1 .. G.N_Edges loop
         if G.Edges (E).Alive then
            G.Nodes (G.Edges (E).From).Out_Deg :=
              G.Nodes (G.Edges (E).From).Out_Deg + 1;
            G.Nodes (G.Edges (E).To).In_Deg :=
              G.Nodes (G.Edges (E).To).In_Deg + 1;
         end if;
      end loop;
   end Recompute_Degrees;

   procedure Rebuild_Out_Lists (G : in out Graph) is
   begin
      G.Out_Counts := [others => 0];
      G.Outs := [others => [others => 0]];
      for E in 1 .. G.N_Edges loop
         if G.Edges (E).Alive then
            declare
               F : constant Node_Index := G.Edges (E).From;
               C : Natural renames G.Out_Counts (F);
            begin
               if C < Max_Out_Degree then
                  C := C + 1;
                  G.Outs (F)(C) := E;
               end if;
            end;
         end if;
      end loop;
   end Rebuild_Out_Lists;

   procedure Prune_Isolates (G : in out Graph) is
   begin
      Recompute_Degrees (G);
      for I in 1 .. G.N_Nodes loop
         if G.Nodes (I).Alive
           and then G.Nodes (I).In_Deg = 0
           and then G.Nodes (I).Out_Deg = 0
         then
            G.Nodes (I).Alive := False;
         end if;
      end loop;
   end Prune_Isolates;

   function Ensure_Node (G : in out Graph; Seq : String) return Node_Index is
      Idx : Node_Index := Find_Node (G, Seq);
   begin
      if Idx /= 0 then
         return Idx;
      end if;
      if G.N_Nodes = Max_Nodes then
         raise Capacity_Exceeded;
      end if;
      G.N_Nodes := G.N_Nodes + 1;
      Idx := G.N_Nodes;
      G.Nodes (Idx).Len := Seq'Length;
      G.Nodes (Idx).Seq (1 .. Seq'Length) := Seq;
      G.Nodes (Idx).Alive := True;
      G.Nodes (Idx).In_Deg := 0;
      G.Nodes (Idx).Out_Deg := 0;
      G.Nodes (Idx).Visited := False;
      return Idx;
   end Ensure_Node;

   procedure Add_Kmer_Edge (G : in out Graph; Kmer : String) is
      --  Kmer length = K; prefix = Kmer(1..K-1), suffix = Kmer(2..K).
      Pref : constant String := Kmer (Kmer'First .. Kmer'Last - 1);
      Suff : constant String := Kmer (Kmer'First + 1 .. Kmer'Last);
      Fi, Ti : Node_Index;
      Found  : Edge_Index := 0;
   begin
      Fi := Ensure_Node (G, Pref);
      Ti := Ensure_Node (G, Suff);

      --  Look for existing edge Fi → Ti among Fi's out-list.
      for J in 1 .. G.Out_Counts (Fi) loop
         declare
            E : constant Edge_Index := G.Outs (Fi)(J);
         begin
            if E /= 0 and then G.Edges (E).Alive
              and then G.Edges (E).To = Ti
            then
               Found := E;
               exit;
            end if;
         end;
      end loop;

      if Found /= 0 then
         G.Edges (Found).Mult := G.Edges (Found).Mult + 1;
      else
         if G.N_Edges = Max_Edges then
            raise Capacity_Exceeded;
         end if;
         if G.Out_Counts (Fi) = Max_Out_Degree then
            raise Capacity_Exceeded;
         end if;
         G.N_Edges := G.N_Edges + 1;
         Found := G.N_Edges;
         G.Edges (Found) :=
           (From => Fi, To => Ti, Mult => 1, Alive => True);
         G.Out_Counts (Fi) := G.Out_Counts (Fi) + 1;
         G.Outs (Fi)(G.Out_Counts (Fi)) := Found;
         G.Nodes (Fi).Out_Deg := G.Nodes (Fi).Out_Deg + 1;
         G.Nodes (Ti).In_Deg := G.Nodes (Ti).In_Deg + 1;
      end if;
   end Add_Kmer_Edge;

   procedure Hash_Sequence (G : in out Graph; Seq : String) is
      K : constant Kmer_Length := G.K;
   begin
      if Seq'Length < K then
         return;
      end if;
      for Start in Seq'First .. Seq'Last - K + 1 loop
         declare
            Window : constant String := Seq (Start .. Start + K - 1);
            Ok     : Boolean := True;
            Norm   : String (1 .. K);
         begin
            for I in Window'Range loop
               if not Is_ACGT (Window (I)) then
                  Ok := False;
                  exit;
               end if;
               Norm (I - Window'First + 1) := Normalize_Base (Window (I));
            end loop;
            if Ok then
               Add_Kmer_Edge (G, Norm);
            end if;
         end;
      end loop;
   end Hash_Sequence;

   function Alive_Out_Edge
     (G : Graph; N : Node_Index; Which : Positive) return Edge_Index
   is
      Seen : Natural := 0;
   begin
      for J in 1 .. G.Out_Counts (N) loop
         declare
            E : constant Edge_Index := G.Outs (N)(J);
         begin
            if E /= 0 and then G.Edges (E).Alive then
               Seen := Seen + 1;
               if Seen = Which then
                  return E;
               end if;
            end if;
         end;
      end loop;
      return 0;
   end Alive_Out_Edge;

   function First_Alive_Out (G : Graph; N : Node_Index) return Edge_Index is
   begin
      return Alive_Out_Edge (G, N, 1);
   end First_Alive_Out;

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Is_ACGT (C : Character) return Boolean is
      U : constant Character := Upper (C);
   begin
      return U = 'A' or else U = 'C' or else U = 'G' or else U = 'T';
   end Is_ACGT;

   function Normalize_Base (C : Character) return Character is
      U : constant Character := Upper (C);
   begin
      if U = 'A' or else U = 'C' or else U = 'G' or else U = 'T' then
         return U;
      end if;
      raise Invalid_Argument;
   end Normalize_Base;

   function Reverse_Complement (S : String) return String is
      R : String (1 .. S'Length);
      U : Character;
   begin
      if S'Length > Max_Read_Length then
         raise Invalid_Argument;
      end if;
      for I in S'Range loop
         U := Upper (S (I));
         case U is
            when 'A' => U := 'T';
            when 'T' => U := 'A';
            when 'C' => U := 'G';
            when 'G' => U := 'C';
            when others =>
               null;  -- leave non-ACGT as uppercased original
         end case;
         R (S'Last - I + 1) := U;
      end loop;
      return R;
   end Reverse_Complement;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Contains_Substring (Haystack, Needle : String) return Boolean is
   begin
      if Needle'Length = 0 then
         return True;
      end if;
      if Needle'Length > Haystack'Length then
         return False;
      end if;
      for I in Haystack'First .. Haystack'Last - Needle'Length + 1 loop
         if Haystack (I .. I + Needle'Length - 1) = Needle then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Substring;

   -------------------------------------------------------------------------
   -- Construction
   -------------------------------------------------------------------------

   function Build_Graph (K : Kmer_Length) return Graph is
      G : Graph;
   begin
      G.K := K;
      G.N_Nodes := 0;
      G.N_Edges := 0;
      G.Read_Count := 0;
      return G;
   end Build_Graph;

   function Get_K (G : Graph) return Kmer_Length is
   begin
      return G.K;
   end Get_K;

   procedure Add_Read
     (G          : in out Graph;
      Read       : String;
      Include_RC : Boolean := True)
   is
   begin
      if Read'Length > Max_Read_Length then
         raise Invalid_Argument;
      end if;
      if G.Read_Count = Max_Reads then
         raise Capacity_Exceeded;
      end if;
      G.Read_Count := G.Read_Count + 1;
      Hash_Sequence (G, Read);
      if Include_RC and then Read'Length > 0 then
         Hash_Sequence (G, Reverse_Complement (Read));
      end if;
   end Add_Read;

   -------------------------------------------------------------------------
   -- Tip removal
   -------------------------------------------------------------------------

   procedure Remove_Tips
     (G              : in out Graph;
      Max_Tip_Length : Natural := 0)
   is
      Limit : Natural := Max_Tip_Length;
      Changed : Boolean := True;
      Passes  : Natural := 0;
   begin
      if Limit = 0 then
         Limit := 2 * Natural (G.K);
      end if;

      while Changed and then Passes < Max_Nodes loop
         Changed := False;
         Passes := Passes + 1;
         Recompute_Degrees (G);
         Rebuild_Out_Lists (G);

         for I in 1 .. G.N_Nodes loop
            if G.Nodes (I).Alive then
               --  Out-tip: out-degree 0, in-degree 1 → walk backward short path
               if G.Nodes (I).Out_Deg = 0 and then G.Nodes (I).In_Deg <= 1 then
                  declare
                     Cur   : Node_Index := I;
                     Steps : Natural := 0;
                     Path  : array (1 .. Max_Nodes) of Node_Index;
                  begin
                     while Cur /= 0
                       and then G.Nodes (Cur).Alive
                       and then G.Nodes (Cur).Out_Deg <= 1
                       and then G.Nodes (Cur).In_Deg <= 1
                       and then Steps < Limit
                     loop
                        Steps := Steps + 1;
                        Path (Steps) := Cur;
                        --  Find unique predecessor edge.
                        declare
                           Pred : Node_Index := 0;
                           Pred_E : Edge_Index := 0;
                        begin
                           for E in 1 .. G.N_Edges loop
                              if G.Edges (E).Alive
                                and then G.Edges (E).To = Cur
                              then
                                 Pred := G.Edges (E).From;
                                 Pred_E := E;
                                 exit;
                              end if;
                           end loop;
                           if Pred_E /= 0 then
                              G.Edges (Pred_E).Alive := False;
                              Changed := True;
                           end if;
                           --  Stop extending if predecessor branches.
                           if Pred = 0 then
                              Cur := 0;
                           elsif G.Nodes (Pred).Out_Deg > 1
                             or else G.Nodes (Pred).In_Deg > 1
                           then
                              Cur := 0;
                           else
                              Cur := Pred;
                           end if;
                        end;
                     end loop;
                     for S in 1 .. Steps loop
                        G.Nodes (Path (S)).Alive := False;
                     end loop;
                  end;
               end if;

               --  In-tip: in-degree 0, out-degree 1 → walk forward short path
               if G.Nodes (I).Alive
                 and then G.Nodes (I).In_Deg = 0
                 and then G.Nodes (I).Out_Deg <= 1
               then
                  declare
                     Cur   : Node_Index := I;
                     Steps : Natural := 0;
                     Path  : array (1 .. Max_Nodes) of Node_Index;
                  begin
                     while Cur /= 0
                       and then G.Nodes (Cur).Alive
                       and then G.Nodes (Cur).In_Deg <= 1
                       and then G.Nodes (Cur).Out_Deg <= 1
                       and then Steps < Limit
                     loop
                        Steps := Steps + 1;
                        Path (Steps) := Cur;
                        declare
                           E : constant Edge_Index := First_Alive_Out (G, Cur);
                           Nxt : Node_Index := 0;
                        begin
                           if E /= 0 then
                              Nxt := G.Edges (E).To;
                              G.Edges (E).Alive := False;
                              Changed := True;
                              if G.Nodes (Nxt).In_Deg > 1
                                or else G.Nodes (Nxt).Out_Deg > 1
                              then
                                 Cur := 0;
                              else
                                 Cur := Nxt;
                              end if;
                           else
                              Cur := 0;
                           end if;
                        end;
                     end loop;
                     for S in 1 .. Steps loop
                        G.Nodes (Path (S)).Alive := False;
                     end loop;
                  end;
               end if;
            end if;
         end loop;

         Rebuild_Out_Lists (G);
         Recompute_Degrees (G);
      end loop;

      --  Kill edges touching dead nodes.
      for E in 1 .. G.N_Edges loop
         if G.Edges (E).Alive then
            if not G.Nodes (G.Edges (E).From).Alive
              or else not G.Nodes (G.Edges (E).To).Alive
            then
               G.Edges (E).Alive := False;
            end if;
         end if;
      end loop;
      Rebuild_Out_Lists (G);
      Prune_Isolates (G);
      Rebuild_Out_Lists (G);
      Recompute_Degrees (G);
   end Remove_Tips;

   -------------------------------------------------------------------------
   -- Low coverage
   -------------------------------------------------------------------------

   procedure Remove_Low_Coverage
     (G            : in out Graph;
      Min_Coverage : Natural)
   is
   begin
      for E in 1 .. G.N_Edges loop
         if G.Edges (E).Alive and then G.Edges (E).Mult < Min_Coverage then
            G.Edges (E).Alive := False;
         end if;
      end loop;
      Rebuild_Out_Lists (G);
      Prune_Isolates (G);
      Rebuild_Out_Lists (G);
      Recompute_Degrees (G);
   end Remove_Low_Coverage;

   -------------------------------------------------------------------------
   -- Contig emission
   -------------------------------------------------------------------------

   function Contig_String (C : Contig_Record) return String is
   begin
      return C.Seq (1 .. C.Len);
   end Contig_String;

   procedure Append_Contig
     (List : in out Contig_List;
      Seq  : String)
   is
   begin
      if Seq'Length = 0 then
         return;
      end if;
      if List.Count = Max_Contigs then
         return;
      end if;
      List.Count := List.Count + 1;
      declare
         L : Natural := Seq'Length;
      begin
         if L > Max_Contig_Length then
            L := Max_Contig_Length;
         end if;
         List.Contigs (List.Count).Len := L;
         List.Contigs (List.Count).Seq (1 .. L) :=
           Seq (Seq'First .. Seq'First + L - 1);
      end;
   end Append_Contig;

   function Emit_Contigs (G : Graph) return Contig_List is
      Result : Contig_List;
      GG     : Graph := G;  -- mutable copy for Visited flags
      K1     : constant Natural := Natural (G.K) - 1;
   begin
      Recompute_Degrees (GG);
      Rebuild_Out_Lists (GG);

      for I in 1 .. GG.N_Nodes loop
         GG.Nodes (I).Visited := False;
      end loop;

      --  Start walks at sources of unbranched paths: alive nodes with
      --  (in-degree ≠ 1) or (out-degree ≠ 1), preferring in-degree 0,
      --  plus any unused single-edge chains.
      for Start in 1 .. GG.N_Nodes loop
         if GG.Nodes (Start).Alive
           and then not GG.Nodes (Start).Visited
           and then (GG.Nodes (Start).In_Deg /= 1
                     or else GG.Nodes (Start).Out_Deg /= 1)
         then
            --  Only emit if this node starts an outgoing walk or is isolated.
            if GG.Nodes (Start).Out_Deg >= 1
              or else GG.Nodes (Start).In_Deg = 0
            then
               declare
                  Cur    : Node_Index := Start;
                  Buf    : String (1 .. Max_Contig_Length);
                  Len    : Natural := 0;
                  First  : Boolean := True;
               begin
                  while Cur /= 0
                    and then GG.Nodes (Cur).Alive
                    and then not GG.Nodes (Cur).Visited
                  loop
                     GG.Nodes (Cur).Visited := True;
                     if First then
                        declare
                           S : constant String := Node_Key (GG.Nodes (Cur));
                        begin
                           if S'Length <= Max_Contig_Length then
                              Len := S'Length;
                              Buf (1 .. Len) := S;
                           end if;
                        end;
                        First := False;
                     else
                        --  Append last character of this (k-1)-mer.
                        if Len < Max_Contig_Length
                          and then GG.Nodes (Cur).Len > 0
                        then
                           Len := Len + 1;
                           Buf (Len) :=
                             GG.Nodes (Cur).Seq (GG.Nodes (Cur).Len);
                        end if;
                     end if;

                     --  Continue only along unique unbranched out-edge
                     --  into a node with in-degree 1 (or the next start).
                     if GG.Nodes (Cur).Out_Deg = 1 then
                        declare
                           E : constant Edge_Index :=
                             First_Alive_Out (GG, Cur);
                        begin
                           if E = 0 then
                              Cur := 0;
                           else
                              declare
                                 Nxt : constant Node_Index :=
                                   GG.Edges (E).To;
                              begin
                                 if GG.Nodes (Nxt).Visited then
                                    Cur := 0;
                                 elsif GG.Nodes (Nxt).In_Deg > 1 then
                                    --  Include the junction base then stop;
                                    --  junction itself can start another walk.
                                    if not GG.Nodes (Nxt).Visited then
                                       if Len < Max_Contig_Length
                                         and then GG.Nodes (Nxt).Len > 0
                                       then
                                          Len := Len + 1;
                                          Buf (Len) :=
                                            GG.Nodes (Nxt).Seq
                                              (GG.Nodes (Nxt).Len);
                                       end if;
                                    end if;
                                    Cur := 0;
                                 elsif GG.Nodes (Nxt).Out_Deg > 1 then
                                    if not GG.Nodes (Nxt).Visited then
                                       GG.Nodes (Nxt).Visited := True;
                                       if Len < Max_Contig_Length
                                         and then GG.Nodes (Nxt).Len > 0
                                       then
                                          Len := Len + 1;
                                          Buf (Len) :=
                                            GG.Nodes (Nxt).Seq
                                              (GG.Nodes (Nxt).Len);
                                       end if;
                                    end if;
                                    Cur := 0;
                                 else
                                    Cur := Nxt;
                                 end if;
                              end;
                           end if;
                        end;
                     else
                        Cur := 0;
                     end if;
                  end loop;

                  if Len >= K1 then
                     Append_Contig (Result, Buf (1 .. Len));
                  end if;
               end;
            end if;
         end if;
      end loop;

      --  Remaining unvisited unbranched cycles / pure paths.
      for Start in 1 .. GG.N_Nodes loop
         if GG.Nodes (Start).Alive and then not GG.Nodes (Start).Visited then
            declare
               Cur   : Node_Index := Start;
               Buf   : String (1 .. Max_Contig_Length);
               Len   : Natural := 0;
               First : Boolean := True;
               Guard : Natural := 0;
            begin
               while Cur /= 0
                 and then GG.Nodes (Cur).Alive
                 and then not GG.Nodes (Cur).Visited
                 and then Guard < Max_Nodes
               loop
                  Guard := Guard + 1;
                  GG.Nodes (Cur).Visited := True;
                  if First then
                     declare
                        S : constant String := Node_Key (GG.Nodes (Cur));
                     begin
                        Len := S'Length;
                        if Len > Max_Contig_Length then
                           Len := Max_Contig_Length;
                        end if;
                        Buf (1 .. Len) := S (S'First .. S'First + Len - 1);
                     end;
                     First := False;
                  else
                     if Len < Max_Contig_Length
                       and then GG.Nodes (Cur).Len > 0
                     then
                        Len := Len + 1;
                        Buf (Len) := GG.Nodes (Cur).Seq (GG.Nodes (Cur).Len);
                     end if;
                  end if;
                  if GG.Nodes (Cur).Out_Deg = 1 then
                     declare
                        E : constant Edge_Index := First_Alive_Out (GG, Cur);
                     begin
                        if E = 0 then
                           Cur := 0;
                        else
                           Cur := GG.Edges (E).To;
                           if GG.Nodes (Cur).Visited then
                              Cur := 0;
                           end if;
                        end if;
                     end;
                  else
                     Cur := 0;
                  end if;
               end loop;
               if Len >= K1 then
                  Append_Contig (Result, Buf (1 .. Len));
               end if;
            end;
         end if;
      end loop;

      return Result;
   end Emit_Contigs;

   -------------------------------------------------------------------------
   -- Queries
   -------------------------------------------------------------------------

   function Node_Count (G : Graph) return Natural is
      C : Natural := 0;
   begin
      for I in 1 .. G.N_Nodes loop
         if G.Nodes (I).Alive then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Node_Count;

   function Edge_Count (G : Graph) return Natural is
      C : Natural := 0;
   begin
      for E in 1 .. G.N_Edges loop
         if G.Edges (E).Alive then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Edge_Count;

   function Contains_Node (G : Graph; Seq : String) return Boolean is
   begin
      return Find_Node (G, Seq) /= 0;
   end Contains_Node;

   function Edge_Multiplicity
     (G : Graph; From_Seq, To_Seq : String) return Natural
   is
      Fi : constant Node_Index := Find_Node (G, From_Seq);
      Ti : constant Node_Index := Find_Node (G, To_Seq);
   begin
      if Fi = 0 or else Ti = 0 then
         return 0;
      end if;
      for J in 1 .. G.Out_Counts (Fi) loop
         declare
            E : constant Edge_Index := G.Outs (Fi)(J);
         begin
            if E /= 0 and then G.Edges (E).Alive
              and then G.Edges (E).To = Ti
            then
               return G.Edges (E).Mult;
            end if;
         end;
      end loop;
      return 0;
   end Edge_Multiplicity;

end Velvet;
