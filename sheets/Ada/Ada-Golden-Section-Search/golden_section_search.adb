package body Golden_Section_Search is
   procedure Validate
     (A, B   : Scalar;
      Config : Search_Config)
   is
   begin
      if A >= B then
         raise Constraint_Error with "search interval requires A < B";
      end if;
      if Config.Tol <= 0.0 then
         raise Constraint_Error with "Tol must be positive";
      end if;
   end Validate;

   function Better
     (Left, Right : Scalar;
      Mode        : Search_Mode) return Boolean
   is
     (case Mode is
         when Find_Minimum => Left <= Right,
         when Find_Maximum => Left >= Right);

   function Near
     (Left, Right : Scalar;
      Tol         : Scalar := 1.0E-9) return Boolean
   is
     (abs (Left - Right) <= Tol);

   function Golden_Probes (A, B : Scalar) return Probe_Pair is
      Width : constant Scalar := B - A;
   begin
      if A >= B then
         raise Constraint_Error with "probe interval requires A < B";
      end if;
      return (Lower => B - Tau * Width,
              Upper => A + Tau * Width);
   end Golden_Probes;

   function Golden_Search
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Mode   : Search_Mode;
      Config : Search_Config) return Search_Result
   is
      Left  : Scalar := A;
      Right : Scalar := B;
      P     : constant Probe_Pair := Golden_Probes (A, B);
      C     : Scalar := P.Lower;
      D     : Scalar := P.Upper;
      FC    : Scalar := F (C);
      FD    : Scalar := F (D);
      Count : Natural := 0;
   begin
      Validate (A, B, Config);

      while Right - Left > Config.Tol
        and then Count < Config.Max_Iterations
      loop
         if Better (FC, FD, Mode) then
            Right := D;
            D     := C;
            FD    := FC;
            C     := Right - Tau * (Right - Left);
            FC    := F (C);
         else
            Left := C;
            C    := D;
            FC   := FD;
            D    := Left + Tau * (Right - Left);
            FD   := F (D);
         end if;
         Count := Count + 1;
      end loop;

      declare
         FL     : constant Scalar := F (Left);
         FR     : constant Scalar := F (Right);
         X_Best : Scalar := C;
         F_Best : Scalar := FC;
      begin
         if Better (FD, F_Best, Mode) then
            X_Best := D;
            F_Best := FD;
         end if;
         if Better (FL, F_Best, Mode) then
            X_Best := Left;
            F_Best := FL;
         end if;
         if Better (FR, F_Best, Mode) then
            X_Best := Right;
            F_Best := FR;
         end if;
         return (X_Star     => X_Best,
                 F_Star     => F_Best,
                 Iterations => Count,
                 Bracket    => (Left => Left, Right => Right));
      end;
   end Golden_Search;

   function Minimize
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Config : Search_Config := (others => <>)) return Search_Result
   is
   begin
      return Golden_Search (F, A, B, Find_Minimum, Config);
   end Minimize;

   function Maximize
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Config : Search_Config := (others => <>)) return Search_Result
   is
   begin
      return Golden_Search (F, A, B, Find_Maximum, Config);
   end Maximize;

   function Fibonacci_Number (N : Natural) return Scalar is
      Previous : Scalar := 0.0;
      Current  : Scalar := 1.0;
   begin
      for K in 1 .. N loop
         declare
            Next_Value : constant Scalar := Previous + Current;
         begin
            Previous := Current;
            Current  := Next_Value;
         end;
      end loop;
      return Previous;
   end Fibonacci_Number;

   function Fibonacci_Search
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Mode   : Search_Mode := Find_Minimum;
      Config : Search_Config := (others => <>)) return Search_Result
   is
      Left     : Scalar := A;
      Right    : Scalar := B;
      Required : Scalar;
      N        : Natural := 2;
      C        : Scalar;
      D        : Scalar;
      FC       : Scalar;
      FD       : Scalar;
      Count    : Natural := 0;
   begin
      Validate (A, B, Config);
      Required := (B - A) / Config.Tol;

      while Fibonacci_Number (N) < Required
        and then N < Config.Max_Iterations + 2
      loop
         N := N + 1;
      end loop;

      C := Left + Fibonacci_Number (N - 2) / Fibonacci_Number (N)
        * (Right - Left);
      D := Left + Fibonacci_Number (N - 1) / Fibonacci_Number (N)
        * (Right - Left);
      FC := F (C);
      FD := F (D);

      if N > 2 then
         for K in 1 .. N - 2 loop
            exit when Count >= Config.Max_Iterations
              or else Right - Left <= Config.Tol;
            if Better (FC, FD, Mode) then
               Right := D;
               D     := C;
               FD    := FC;
               C := Left
                 + Fibonacci_Number (N - K - 2)
                 / Fibonacci_Number (N - K) * (Right - Left);
               FC := F (C);
            else
               Left := C;
               C    := D;
               FC   := FD;
               D := Left
                 + Fibonacci_Number (N - K - 1)
                 / Fibonacci_Number (N - K) * (Right - Left);
               FD := F (D);
            end if;
            Count := Count + 1;
         end loop;
      end if;

      declare
         FL     : constant Scalar := F (Left);
         FR     : constant Scalar := F (Right);
         X_Best : Scalar := C;
         F_Best : Scalar := FC;
      begin
         if Better (FD, F_Best, Mode) then
            X_Best := D;
            F_Best := FD;
         end if;
         if Better (FL, F_Best, Mode) then
            X_Best := Left;
            F_Best := FL;
         end if;
         if Better (FR, F_Best, Mode) then
            X_Best := Right;
            F_Best := FR;
         end if;
         return (X_Star     => X_Best,
                 F_Star     => F_Best,
                 Iterations => Count,
                 Bracket    => (Left => Left, Right => Right));
      end;
   end Fibonacci_Search;

   function Quartic_Unimodal (X : Scalar) return Scalar is
      Offset : constant Scalar := X - 1.5;
   begin
      return Offset ** 4 + 0.1 * Offset ** 2;
   end Quartic_Unimodal;

   function Negative_Quadratic_Max (X : Scalar) return Scalar is
   begin
      return -(X - 3.0) ** 2;
   end Negative_Quadratic_Max;

   function Sphere_On_Line (X : Scalar) return Scalar is
   begin
      return (1.0 - X) ** 2
        + (-2.0 + 2.0 * X) ** 2
        + (3.0 - 3.0 * X) ** 2;
   end Sphere_On_Line;

   function Increasing_Boundary (X : Scalar) return Scalar is
   begin
      return X;
   end Increasing_Boundary;

   function Decreasing_Boundary (X : Scalar) return Scalar is
   begin
      return -X;
   end Decreasing_Boundary;
end Golden_Section_Search;
