--  Gene_Expression_Programming — Ada 2023 educational package for Wikipedia
--  "Gene expression programming" (Ferreira 2001): genotype–phenotype EA
--  with fixed-length linear genes (head + tail) decoded via Karva /
--  level-order into expression trees. Tiny symbolic-regression driver
--  with +, -, *, / (protected), terminals a, b, optional ephemeral '?'.
--  Primary source: https://en.wikipedia.org/wiki/Gene_expression_programming
--  Sibling: Ada-Genetic-Algorithms (README links; no package deps).

pragma Ada_2022;

package Gene_Expression_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Educational caps: head h ≤ 6, population ≤ 40.
   Max_Head : constant := 6;
   Max_Nmax : constant := 2;  -- binary ops only
   --  t = h*(n_max-1)+1 ≤ 6*1+1 = 7; gene length ≤ 6+7 = 13
   Max_Gene_Len : constant := Max_Head + Max_Head * (Max_Nmax - 1) + 1;
   Max_Pop      : constant := 40;
   Max_Samples  : constant := 32;
   Max_Gens     : constant := 200;

   subtype Head_Len is Positive range 1 .. Max_Head;
   subtype Gene_Len is Positive range 1 .. Max_Gene_Len;
   subtype Pop_Size_T is Positive range 2 .. Max_Pop;
   subtype Sample_Count is Positive range 1 .. Max_Samples;
   subtype Tourney_K is Positive range 2 .. Max_Pop;
   subtype Elite_T is Natural range 0 .. Max_Pop;

   --  Symbols: functions '+','-','*','/'; terminals 'a','b'; ephemeral '?'.
   subtype Symbol is Character;

   type Symbol_Array is array (Positive range <>) of Symbol;

   --  Fixed-capacity gene: head (funcs+terms) + tail (terminals only).
   --  Length = Head + Tail_Length(Head); unused slots past Length ignored.
   --  Ephemeral : value substituted wherever '?' appears in the ORF.
   type Gene is record
      Symbols   : Symbol_Array (1 .. Max_Gene_Len) := [others => 'a'];
      Head      : Head_Len := 1;
      Length    : Gene_Len := 2;  -- Head + Tail
      Ephemeral : Real     := 1.0;
   end record;

   type Gene_Array is array (Positive range <>) of Gene;

   type Sample is record
      A, B, Target : Real := 0.0;
   end record;

   type Sample_Array is array (Positive range <>) of Sample;

   type Fitness_Array is array (Positive range <>) of Real;

   --  Pop_Size / Generations / rates / tournament / elitism / seed
   type Config is record
      Pop_Size       : Pop_Size_T    := 20;
      Generations    : Natural       := 40;
      Head           : Head_Len      := 3;
      Crossover_Rate : Unit_Interval := 0.7;
      Mutation_Rate  : Unit_Interval := 0.1;
      Tournament_K   : Tourney_K     := 3;
      Elite_Count    : Elite_T       := 1;
      Seed           : Natural       := 1;
      Use_Ephemeral  : Boolean       := False;
   end record;

   type Result is record
      Best           : Gene    := (others => <>);
      Best_Fitness   : Real    := 0.0;
      Best_MSE       : Real    := Real'Last;
      Generations_Run : Natural := 0;
      Evaluations    : Natural := 0;
      History_Length : Natural := 0;
   end record;

   type Target_Kind is (Sum_AB, Product_AB, Diff_AB);

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;
   Protected_Div_Eps : constant Real := 1.0E-12;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Pop_Size       : Pop_Size_T    := 20;
      Generations    : Natural       := 40;
      Head           : Head_Len      := 3;
      Crossover_Rate : Unit_Interval := 0.7;
      Mutation_Rate  : Unit_Interval := 0.1;
      Tournament_K   : Tourney_K     := 3;
      Elite_Count    : Elite_T       := 1;
      Seed           : Natural       := 1;
      Use_Ephemeral  : Boolean       := False) return Config
     with Global => null;

   function Config_Is_Valid (Cfg : Config) return Boolean
     with Global => null;
   --  True iff Tournament_K ≤ Pop_Size and Elite_Count < Pop_Size.

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG)
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Gene geometry (Ferreira length rule)
   ---------------------------------------------------------------------------

   function Tail_Length (H : Head_Len; N_Max : Positive := Max_Nmax)
     return Positive
     with Pre => N_Max >= 1, Global => null;
   --  t = h*(n_max - 1) + 1

   function Gene_Length_Of (H : Head_Len; N_Max : Positive := Max_Nmax)
     return Gene_Len
     with Global => null;
   --  g = h + t

   function Is_Function (S : Symbol) return Boolean
     with Global => null;

   function Is_Terminal (S : Symbol) return Boolean
     with Global => null;

   function Arity_Of (S : Symbol) return Natural
     with Global => null;
   --  2 for binary ops, 0 for terminals; 0 if unknown.

   function Gene_Is_Well_Formed (G : Gene) return Boolean
     with Global => null;
   --  Length = Gene_Length_Of(Head); head symbols in F∪T; tail in T only.

   ---------------------------------------------------------------------------
   -- Construction / random / genetic operators
   ---------------------------------------------------------------------------

   function Make_Gene
     (Symbols   : Symbol_Array;
      Head      : Head_Len;
      Ephemeral : Real := 1.0) return Gene
     with Pre => Symbols'Length = Gene_Length_Of (Head),
          Global => null;

   function Random_Gene
     (State         : in out RNG_State;
      Head          : Head_Len;
      Use_Ephemeral : Boolean := False) return Gene
     with Global => null;

   procedure Mutate
     (G             : in out Gene;
      State         : in out RNG_State;
      Rate          : Unit_Interval;
      Use_Ephemeral : Boolean := False)
     with Global => null;
   --  Per-locus: head ← F∪T; tail ← T only (preserves validity).

   procedure Crossover_One_Point
     (A, B   : Gene;
      Child1 : out Gene;
      Child2 : out Gene;
      State  : in out RNG_State)
     with Pre => A.Head = B.Head and then A.Length = B.Length,
          Global => null;
   --  Homologous 1-point recombination; offspring stay valid.

   procedure Transpose_Stub
     (G     : in out Gene;
      State : in out RNG_State)
     with Global => null;
   --  Educational stub: optionally copy a short head subsequence
   --  to another head position (overwrite), preserving length/tail.

   ---------------------------------------------------------------------------
   -- Decode (Karva / ORF) and evaluate
   ---------------------------------------------------------------------------

   function ORF_Length (G : Gene) return Natural
     with Global => null;
   --  Number of symbols in the open reading frame (≤ Length).

   function Evaluate
     (G : Gene; A, B : Real) return Real
     with Global => null;
   --  Stack / level-order evaluation of the Karva ORF; protected '/'.

   function Protected_Divide (Num, Den : Real) return Real
     with Global => null;
   --  Num/Den if |Den| > eps else Num (educational protected division).

   function MSE
     (G : Gene; Data : Sample_Array) return Non_Negative
     with Pre => Data'Length >= 1, Global => null;

   function Fitness_From_MSE (Err : Real) return Non_Negative
     with Global => null;
   --  1 / (1 + MSE)

   function Fitness_Of
     (G : Gene; Data : Sample_Array) return Non_Negative
     with Pre => Data'Length >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Toy datasets / evolution
   ---------------------------------------------------------------------------

   function Make_Toy_Data
     (Kind  : Target_Kind;
      Count : Sample_Count;
      State : in out RNG_State;
      Lo    : Real := -2.0;
      Hi    : Real := 2.0) return Sample_Array
     with Global => null;

   function Evolve
     (Data : Sample_Array;
      Cfg  : Config) return Result
     with Pre => Data'Length >= 1 and then Config_Is_Valid (Cfg),
          Global => null;

   function Fit_Symbolic
     (Kind : Target_Kind;
      Cfg  : Config) return Result
     with Pre => Config_Is_Valid (Cfg), Global => null;
   --  Build a small toy set for Kind, then Evolve.

end Gene_Expression_Programming;
