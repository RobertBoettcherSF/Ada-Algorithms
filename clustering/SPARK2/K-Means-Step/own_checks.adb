pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). References: Nearest by comparing
--  abs (P - C1) with abs (P - C2) (ties go to cluster 1), exhaustive over
--  every P, C1, C2 in 0 .. 100; Step's new centroid as the largest M with
--  M * (N + 1) <= C * N + P, found by counting up (no division), over
--  every P, C in 0 .. 100 and N in 0 .. 7.
with Ada.Text_IO;
with K_Means_Step; use K_Means_Step;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Floor_Mean (C, N, P : Natural) return Natural is
      M : Natural := 0;
   begin
      while (M + 1) * (N + 1) <= C * N + P loop
         M := M + 1;
      end loop;
      return M;
   end Floor_Mean;
begin
   for P in Point loop
      for C1 in Point loop
         for C2 in Point loop
            Report (Nearest (P, C1, C2) = (if abs (P - C1) <= abs (P - C2) then 1 else 2),
                    "Nearest" & P'Image & C1'Image & C2'Image);
         end loop;
      end loop;
   end loop;

   for P in Point loop
      for C in Point loop
         for N in 0 .. Max_N - 1 loop
            declare
               M : constant Natural := Floor_Mean (C, N, P);
               --  Cluster 1 at C (wins: it is nearer or tied); cluster 2 at
               --  the far end from P, unless it is tied.
               C1 : Point := C;
               C2 : Point := (if P <= 50 then 100 else 0);
               N1 : Count := N;
               N2 : Count := 0;
               Wins_1 : constant Boolean := abs (P - C) <= abs (P - C2);
            begin
               Step (P, C1, C2, N1, N2);
               if Wins_1 then
                  Report (C1 = M and then N1 = N + 1
                          and then C2 = (if P <= 50 then 100 else 0) and then N2 = 0,
                          "Step 1" & P'Image & C'Image & N'Image);
               end if;
               --  The same centroid as cluster 2, cluster 1 far away.
               C1 := (if P <= 50 then 100 else 0);
               C2 := C;
               N1 := 0;
               N2 := N;
               Step (P, C1, C2, N1, N2);
               if abs (P - C) < abs (P - (if P <= 50 then 100 else 0)) then
                  Report (C2 = M and then N2 = N + 1
                          and then C1 = (if P <= 50 then 100 else 0) and then N1 = 0,
                          "Step 2" & P'Image & C'Image & N'Image);
               end if;
            end;
         end loop;
      end loop;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
