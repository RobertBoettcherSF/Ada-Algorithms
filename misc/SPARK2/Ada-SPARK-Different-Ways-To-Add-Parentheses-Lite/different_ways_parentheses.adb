pragma Ada_2022;
package body Different_Ways_Parentheses with SPARK_Mode => On is

   package LLI_Conversions is new Signed_Conversions (Int => Long_Long_Integer);
   function Big (V : Long_Long_Integer) return Big_Integer renames LLI_Conversions.To_Big_Integer;

   procedure Lemma_Facts is
   begin
      for J in 2 .. Max_Operands loop
         pragma Loop_Invariant (for all I in 2 .. J - 1 => Ways (I) = Partial (I, I - 1));
         case J is
            when 2 =>
               pragma Assert (Partial (2, 1) = To_Big_Integer (1));
            when 3 =>
               pragma Assert (Partial (3, 1) = To_Big_Integer (1));
               pragma Assert (Partial (3, 2) = To_Big_Integer (2));
            when 4 =>
               pragma Assert (Partial (4, 1) = To_Big_Integer (2));
               pragma Assert (Partial (4, 2) = To_Big_Integer (3));
               pragma Assert (Partial (4, 3) = To_Big_Integer (5));
            when 5 =>
               pragma Assert (Partial (5, 1) = To_Big_Integer (5));
               pragma Assert (Partial (5, 2) = To_Big_Integer (7));
               pragma Assert (Partial (5, 3) = To_Big_Integer (9));
               pragma Assert (Partial (5, 4) = To_Big_Integer (14));
            when 6 =>
               pragma Assert (Partial (6, 1) = To_Big_Integer (14));
               pragma Assert (Partial (6, 2) = To_Big_Integer (19));
               pragma Assert (Partial (6, 3) = To_Big_Integer (23));
               pragma Assert (Partial (6, 4) = To_Big_Integer (28));
               pragma Assert (Partial (6, 5) = To_Big_Integer (42));
            when 7 =>
               pragma Assert (Partial (7, 1) = To_Big_Integer (42));
               pragma Assert (Partial (7, 2) = To_Big_Integer (56));
               pragma Assert (Partial (7, 3) = To_Big_Integer (66));
               pragma Assert (Partial (7, 4) = To_Big_Integer (76));
               pragma Assert (Partial (7, 5) = To_Big_Integer (90));
               pragma Assert (Partial (7, 6) = To_Big_Integer (132));
            when 8 =>
               pragma Assert (Partial (8, 1) = To_Big_Integer (132));
               pragma Assert (Partial (8, 2) = To_Big_Integer (174));
               pragma Assert (Partial (8, 3) = To_Big_Integer (202));
               pragma Assert (Partial (8, 4) = To_Big_Integer (227));
               pragma Assert (Partial (8, 5) = To_Big_Integer (255));
               pragma Assert (Partial (8, 6) = To_Big_Integer (297));
               pragma Assert (Partial (8, 7) = To_Big_Integer (429));
            when 9 =>
               pragma Assert (Partial (9, 1) = To_Big_Integer (429));
               pragma Assert (Partial (9, 2) = To_Big_Integer (561));
               pragma Assert (Partial (9, 3) = To_Big_Integer (645));
               pragma Assert (Partial (9, 4) = To_Big_Integer (715));
               pragma Assert (Partial (9, 5) = To_Big_Integer (785));
               pragma Assert (Partial (9, 6) = To_Big_Integer (869));
               pragma Assert (Partial (9, 7) = To_Big_Integer (1_001));
               pragma Assert (Partial (9, 8) = To_Big_Integer (1_430));
            when 10 =>
               pragma Assert (Partial (10, 1) = To_Big_Integer (1_430));
               pragma Assert (Partial (10, 2) = To_Big_Integer (1_859));
               pragma Assert (Partial (10, 3) = To_Big_Integer (2_123));
               pragma Assert (Partial (10, 4) = To_Big_Integer (2_333));
               pragma Assert (Partial (10, 5) = To_Big_Integer (2_529));
               pragma Assert (Partial (10, 6) = To_Big_Integer (2_739));
               pragma Assert (Partial (10, 7) = To_Big_Integer (3_003));
               pragma Assert (Partial (10, 8) = To_Big_Integer (3_432));
               pragma Assert (Partial (10, 9) = To_Big_Integer (4_862));
            when 11 =>
               pragma Assert (Partial (11, 1) = To_Big_Integer (4_862));
               pragma Assert (Partial (11, 2) = To_Big_Integer (6_292));
               pragma Assert (Partial (11, 3) = To_Big_Integer (7_150));
               pragma Assert (Partial (11, 4) = To_Big_Integer (7_810));
               pragma Assert (Partial (11, 5) = To_Big_Integer (8_398));
               pragma Assert (Partial (11, 6) = To_Big_Integer (8_986));
               pragma Assert (Partial (11, 7) = To_Big_Integer (9_646));
               pragma Assert (Partial (11, 8) = To_Big_Integer (10_504));
               pragma Assert (Partial (11, 9) = To_Big_Integer (11_934));
               pragma Assert (Partial (11, 10) = To_Big_Integer (16_796));
            when 12 =>
               pragma Assert (Partial (12, 1) = To_Big_Integer (16_796));
               pragma Assert (Partial (12, 2) = To_Big_Integer (21_658));
               pragma Assert (Partial (12, 3) = To_Big_Integer (24_518));
               pragma Assert (Partial (12, 4) = To_Big_Integer (26_663));
               pragma Assert (Partial (12, 5) = To_Big_Integer (28_511));
               pragma Assert (Partial (12, 6) = To_Big_Integer (30_275));
               pragma Assert (Partial (12, 7) = To_Big_Integer (32_123));
               pragma Assert (Partial (12, 8) = To_Big_Integer (34_268));
               pragma Assert (Partial (12, 9) = To_Big_Integer (37_128));
               pragma Assert (Partial (12, 10) = To_Big_Integer (41_990));
               pragma Assert (Partial (12, 11) = To_Big_Integer (58_786));
            when 13 =>
               pragma Assert (Partial (13, 1) = To_Big_Integer (58_786));
               pragma Assert (Partial (13, 2) = To_Big_Integer (75_582));
               pragma Assert (Partial (13, 3) = To_Big_Integer (85_306));
               pragma Assert (Partial (13, 4) = To_Big_Integer (92_456));
               pragma Assert (Partial (13, 5) = To_Big_Integer (98_462));
               pragma Assert (Partial (13, 6) = To_Big_Integer (104_006));
               pragma Assert (Partial (13, 7) = To_Big_Integer (109_550));
               pragma Assert (Partial (13, 8) = To_Big_Integer (115_556));
               pragma Assert (Partial (13, 9) = To_Big_Integer (122_706));
               pragma Assert (Partial (13, 10) = To_Big_Integer (132_430));
               pragma Assert (Partial (13, 11) = To_Big_Integer (149_226));
               pragma Assert (Partial (13, 12) = To_Big_Integer (208_012));
            when 14 =>
               pragma Assert (Partial (14, 1) = To_Big_Integer (208_012));
               pragma Assert (Partial (14, 2) = To_Big_Integer (266_798));
               pragma Assert (Partial (14, 3) = To_Big_Integer (300_390));
               pragma Assert (Partial (14, 4) = To_Big_Integer (324_700));
               pragma Assert (Partial (14, 5) = To_Big_Integer (344_720));
               pragma Assert (Partial (14, 6) = To_Big_Integer (362_738));
               pragma Assert (Partial (14, 7) = To_Big_Integer (380_162));
               pragma Assert (Partial (14, 8) = To_Big_Integer (398_180));
               pragma Assert (Partial (14, 9) = To_Big_Integer (418_200));
               pragma Assert (Partial (14, 10) = To_Big_Integer (442_510));
               pragma Assert (Partial (14, 11) = To_Big_Integer (476_102));
               pragma Assert (Partial (14, 12) = To_Big_Integer (534_888));
               pragma Assert (Partial (14, 13) = To_Big_Integer (742_900));
            when 15 =>
               pragma Assert (Partial (15, 1) = To_Big_Integer (742_900));
               pragma Assert (Partial (15, 2) = To_Big_Integer (950_912));
               pragma Assert (Partial (15, 3) = To_Big_Integer (1_068_484));
               pragma Assert (Partial (15, 4) = To_Big_Integer (1_152_464));
               pragma Assert (Partial (15, 5) = To_Big_Integer (1_220_532));
               pragma Assert (Partial (15, 6) = To_Big_Integer (1_280_592));
               pragma Assert (Partial (15, 7) = To_Big_Integer (1_337_220));
               pragma Assert (Partial (15, 8) = To_Big_Integer (1_393_848));
               pragma Assert (Partial (15, 9) = To_Big_Integer (1_453_908));
               pragma Assert (Partial (15, 10) = To_Big_Integer (1_521_976));
               pragma Assert (Partial (15, 11) = To_Big_Integer (1_605_956));
               pragma Assert (Partial (15, 12) = To_Big_Integer (1_723_528));
               pragma Assert (Partial (15, 13) = To_Big_Integer (1_931_540));
               pragma Assert (Partial (15, 14) = To_Big_Integer (2_674_440));
            when 16 =>
               pragma Assert (Partial (16, 1) = To_Big_Integer (2_674_440));
               pragma Assert (Partial (16, 2) = To_Big_Integer (3_417_340));
               pragma Assert (Partial (16, 3) = To_Big_Integer (3_833_364));
               pragma Assert (Partial (16, 4) = To_Big_Integer (4_127_294));
               pragma Assert (Partial (16, 5) = To_Big_Integer (4_362_438));
               pragma Assert (Partial (16, 6) = To_Big_Integer (4_566_642));
               pragma Assert (Partial (16, 7) = To_Big_Integer (4_755_402));
               pragma Assert (Partial (16, 8) = To_Big_Integer (4_939_443));
               pragma Assert (Partial (16, 9) = To_Big_Integer (5_128_203));
               pragma Assert (Partial (16, 10) = To_Big_Integer (5_332_407));
               pragma Assert (Partial (16, 11) = To_Big_Integer (5_567_551));
               pragma Assert (Partial (16, 12) = To_Big_Integer (5_861_481));
               pragma Assert (Partial (16, 13) = To_Big_Integer (6_277_505));
               pragma Assert (Partial (16, 14) = To_Big_Integer (7_020_405));
               pragma Assert (Partial (16, 15) = To_Big_Integer (9_694_845));
            when 17 =>
               pragma Assert (Partial (17, 1) = To_Big_Integer (9_694_845));
               pragma Assert (Partial (17, 2) = To_Big_Integer (12_369_285));
               pragma Assert (Partial (17, 3) = To_Big_Integer (13_855_085));
               pragma Assert (Partial (17, 4) = To_Big_Integer (14_895_145));
               pragma Assert (Partial (17, 5) = To_Big_Integer (15_718_149));
               pragma Assert (Partial (17, 6) = To_Big_Integer (16_423_581));
               pragma Assert (Partial (17, 7) = To_Big_Integer (17_065_365));
               pragma Assert (Partial (17, 8) = To_Big_Integer (17_678_835));
               pragma Assert (Partial (17, 9) = To_Big_Integer (18_292_305));
               pragma Assert (Partial (17, 10) = To_Big_Integer (18_934_089));
               pragma Assert (Partial (17, 11) = To_Big_Integer (19_639_521));
               pragma Assert (Partial (17, 12) = To_Big_Integer (20_462_525));
               pragma Assert (Partial (17, 13) = To_Big_Integer (21_502_585));
               pragma Assert (Partial (17, 14) = To_Big_Integer (22_988_385));
               pragma Assert (Partial (17, 15) = To_Big_Integer (25_662_825));
               pragma Assert (Partial (17, 16) = To_Big_Integer (35_357_670));
            when 18 =>
               pragma Assert (Partial (18, 1) = To_Big_Integer (35_357_670));
               pragma Assert (Partial (18, 2) = To_Big_Integer (45_052_515));
               pragma Assert (Partial (18, 3) = To_Big_Integer (50_401_395));
               pragma Assert (Partial (18, 4) = To_Big_Integer (54_115_895));
               pragma Assert (Partial (18, 5) = To_Big_Integer (57_028_063));
               pragma Assert (Partial (18, 6) = To_Big_Integer (59_497_075));
               pragma Assert (Partial (18, 7) = To_Big_Integer (61_714_147));
               pragma Assert (Partial (18, 8) = To_Big_Integer (63_799_945));
               pragma Assert (Partial (18, 9) = To_Big_Integer (65_844_845));
               pragma Assert (Partial (18, 10) = To_Big_Integer (67_930_643));
               pragma Assert (Partial (18, 11) = To_Big_Integer (70_147_715));
               pragma Assert (Partial (18, 12) = To_Big_Integer (72_616_727));
               pragma Assert (Partial (18, 13) = To_Big_Integer (75_528_895));
               pragma Assert (Partial (18, 14) = To_Big_Integer (79_243_395));
               pragma Assert (Partial (18, 15) = To_Big_Integer (84_592_275));
               pragma Assert (Partial (18, 16) = To_Big_Integer (94_287_120));
               pragma Assert (Partial (18, 17) = To_Big_Integer (129_644_790));
            when 19 =>
               pragma Assert (Partial (19, 1) = To_Big_Integer (129_644_790));
               pragma Assert (Partial (19, 2) = To_Big_Integer (165_002_460));
               pragma Assert (Partial (19, 3) = To_Big_Integer (184_392_150));
               pragma Assert (Partial (19, 4) = To_Big_Integer (197_764_350));
               pragma Assert (Partial (19, 5) = To_Big_Integer (208_164_950));
               pragma Assert (Partial (19, 6) = To_Big_Integer (216_901_454));
               pragma Assert (Partial (19, 7) = To_Big_Integer (224_661_206));
               pragma Assert (Partial (19, 8) = To_Big_Integer (231_866_690));
               pragma Assert (Partial (19, 9) = To_Big_Integer (238_819_350));
               pragma Assert (Partial (19, 10) = To_Big_Integer (245_772_010));
               pragma Assert (Partial (19, 11) = To_Big_Integer (252_977_494));
               pragma Assert (Partial (19, 12) = To_Big_Integer (260_737_246));
               pragma Assert (Partial (19, 13) = To_Big_Integer (269_473_750));
               pragma Assert (Partial (19, 14) = To_Big_Integer (279_874_350));
               pragma Assert (Partial (19, 15) = To_Big_Integer (293_246_550));
               pragma Assert (Partial (19, 16) = To_Big_Integer (312_636_240));
               pragma Assert (Partial (19, 17) = To_Big_Integer (347_993_910));
               pragma Assert (Partial (19, 18) = To_Big_Integer (477_638_700));
            when 20 =>
               pragma Assert (Partial (20, 1) = To_Big_Integer (477_638_700));
               pragma Assert (Partial (20, 2) = To_Big_Integer (607_283_490));
               pragma Assert (Partial (20, 3) = To_Big_Integer (677_998_830));
               pragma Assert (Partial (20, 4) = To_Big_Integer (726_473_055));
               pragma Assert (Partial (20, 5) = To_Big_Integer (763_915_215));
               pragma Assert (Partial (20, 6) = To_Big_Integer (795_117_015));
               pragma Assert (Partial (20, 7) = To_Big_Integer (822_574_599));
               pragma Assert (Partial (20, 8) = To_Big_Integer (847_793_793));
               pragma Assert (Partial (20, 9) = To_Big_Integer (871_812_073));
               pragma Assert (Partial (20, 10) = To_Big_Integer (895_451_117));
               pragma Assert (Partial (20, 11) = To_Big_Integer (919_469_397));
               pragma Assert (Partial (20, 12) = To_Big_Integer (944_688_591));
               pragma Assert (Partial (20, 13) = To_Big_Integer (972_146_175));
               pragma Assert (Partial (20, 14) = To_Big_Integer (1_003_347_975));
               pragma Assert (Partial (20, 15) = To_Big_Integer (1_040_790_135));
               pragma Assert (Partial (20, 16) = To_Big_Integer (1_089_264_360));
               pragma Assert (Partial (20, 17) = To_Big_Integer (1_159_979_700));
               pragma Assert (Partial (20, 18) = To_Big_Integer (1_289_624_490));
               pragma Assert (Partial (20, 19) = To_Big_Integer (1_767_263_190));
         end case;
      end loop;
      pragma Assert (Partial (21, 1) = To_Big_Integer (1_767_263_190));
      pragma Assert (Partial (21, 2) = 2_244_901_890);
      pragma Assert (Partial (21, 3) = 2_504_191_470);
      pragma Assert (Partial (21, 4) = 2_680_979_820);
      pragma Assert (Partial (21, 5) = 2_816_707_650);
      pragma Assert (Partial (21, 6) = 2_929_034_130);
      pragma Assert (Partial (21, 7) = 3_027_096_930);
      pragma Assert (Partial (21, 8) = 3_116_334_078);
      pragma Assert (Partial (21, 9) = 3_200_398_058);
      pragma Assert (Partial (21, 10) = 3_282_060_210);
      pragma Assert (Partial (21, 11) = 3_363_722_362);
      pragma Assert (Partial (21, 12) = 3_447_786_342);
      pragma Assert (Partial (21, 13) = 3_537_023_490);
      pragma Assert (Partial (21, 14) = 3_635_086_290);
      pragma Assert (Partial (21, 15) = 3_747_412_770);
      pragma Assert (Partial (21, 16) = 3_883_140_600);
      pragma Assert (Partial (21, 17) = 4_059_928_950);
      pragma Assert (Partial (21, 18) = 4_319_218_530);
      pragma Assert (Partial (21, 19) = 4_796_857_230);
      pragma Assert (Partial (21, 20) = 6_564_120_420);
   end Lemma_Facts;

   --  Ways (L) for the lengths All_Results handles, as plain counts.
   type Count_Table is array (1 .. Max_Expression) of Positive;
   Count : constant Count_Table := [1, 1, 2, 5, 14, 42, 132, 429, 1_430];

   --  The lemma procedures. Their calls are statements and nothing that is
   --  checked at run time depends on them, so their ghost policy is Ignore
   --  (H191: with -gnata they re-checked O (L ** 2) Big_Integer facts at every
   --  recursive Sub call). Partial, Ways and every Pre, Post, invariant and
   --  Assert of the code below keep the -gnata policy. gnatprove proves the
   --  lemmas and uses their contracts as before (tools/vv/proof_escapes.csv).
   package Lemmas is
      pragma Assertion_Policy (Ghost => Ignore);

      --  The Facts needed for one length L, without the whole table in context.
      procedure Lemma_Ways_Step (L : Operand_Count)
      with
        Ghost,
        Global => null,
        Post   => Ways (L) >= 1 and then Ways (L) <= To_Big_Integer (1_767_263_190)
                  and then (if L >= 2 then Ways (L) = Partial (L, L - 1))
                  and then (if L = 1 then Ways (L) = 1)
                  and then (if L <= Max_Expression then Ways (L) <= To_Big_Integer (Max_Results));

      --  Partial sums grow with S (every term is positive).
      procedure Lemma_Partial_Le (N : Positive; S : Natural)
      with
        Ghost,
        Global             => null,
        Pre                => N in 2 .. Max_Operands + 1 and then S <= N - 1,
        Post               => Partial (N, S) <= Partial (N, N - 1),
        Subprogram_Variant => (Decreases => N - S);

      procedure Lemma_Mul_Mono (X, XX, Y, YY : Big_Integer)
      with
        Ghost,
        Global => null,
        Pre    => 0 <= X and then X <= XX and then 0 <= Y and then Y <= YY,
        Post   => X * Y <= XX * YY;

      --  99 ** L = 99 ** P * 99 ** (L - P).
      procedure Lemma_Bound_Mul (P, L : Positive)
      with
        Ghost,
        Global => null,
        Pre    => L <= Max_Expression and then P < L,
        Post   => Big (Bound (L)) = Big (Bound (P)) * Big (Bound (L - P))
                  and then Bound (P) >= 99 and then Bound (L - P) >= 99
                  and then Bound (L) <= 913_517_247_483_640_899;

      procedure Lemma_Count (L : Positive)
      with
        Ghost,
        Global => null,
        Pre    => L <= Max_Expression,
        Post   => To_Big_Integer (Count (L)) = Ways (L) and then Count (L) <= Max_Results;
   end Lemmas;

   package body Lemmas is
      pragma Assertion_Policy (Ghost => Ignore);

      --  Only the chain for L itself, so that a call costs O (L ** 2) Big_Integer
      --  operations when assertions are enabled (Lemma_Facts would cost every chain).
      procedure Lemma_Ways_Step (L : Operand_Count) is
      begin
         case L is
            when 1 =>
               null;
            when 2 =>
               pragma Assert (Partial (2, 1) = To_Big_Integer (1));
            when 3 =>
               pragma Assert (Partial (3, 1) = To_Big_Integer (1));
               pragma Assert (Partial (3, 2) = To_Big_Integer (2));
            when 4 =>
               pragma Assert (Partial (4, 1) = To_Big_Integer (2));
               pragma Assert (Partial (4, 2) = To_Big_Integer (3));
               pragma Assert (Partial (4, 3) = To_Big_Integer (5));
            when 5 =>
               pragma Assert (Partial (5, 1) = To_Big_Integer (5));
               pragma Assert (Partial (5, 2) = To_Big_Integer (7));
               pragma Assert (Partial (5, 3) = To_Big_Integer (9));
               pragma Assert (Partial (5, 4) = To_Big_Integer (14));
            when 6 =>
               pragma Assert (Partial (6, 1) = To_Big_Integer (14));
               pragma Assert (Partial (6, 2) = To_Big_Integer (19));
               pragma Assert (Partial (6, 3) = To_Big_Integer (23));
               pragma Assert (Partial (6, 4) = To_Big_Integer (28));
               pragma Assert (Partial (6, 5) = To_Big_Integer (42));
            when 7 =>
               pragma Assert (Partial (7, 1) = To_Big_Integer (42));
               pragma Assert (Partial (7, 2) = To_Big_Integer (56));
               pragma Assert (Partial (7, 3) = To_Big_Integer (66));
               pragma Assert (Partial (7, 4) = To_Big_Integer (76));
               pragma Assert (Partial (7, 5) = To_Big_Integer (90));
               pragma Assert (Partial (7, 6) = To_Big_Integer (132));
            when 8 =>
               pragma Assert (Partial (8, 1) = To_Big_Integer (132));
               pragma Assert (Partial (8, 2) = To_Big_Integer (174));
               pragma Assert (Partial (8, 3) = To_Big_Integer (202));
               pragma Assert (Partial (8, 4) = To_Big_Integer (227));
               pragma Assert (Partial (8, 5) = To_Big_Integer (255));
               pragma Assert (Partial (8, 6) = To_Big_Integer (297));
               pragma Assert (Partial (8, 7) = To_Big_Integer (429));
            when 9 =>
               pragma Assert (Partial (9, 1) = To_Big_Integer (429));
               pragma Assert (Partial (9, 2) = To_Big_Integer (561));
               pragma Assert (Partial (9, 3) = To_Big_Integer (645));
               pragma Assert (Partial (9, 4) = To_Big_Integer (715));
               pragma Assert (Partial (9, 5) = To_Big_Integer (785));
               pragma Assert (Partial (9, 6) = To_Big_Integer (869));
               pragma Assert (Partial (9, 7) = To_Big_Integer (1_001));
               pragma Assert (Partial (9, 8) = To_Big_Integer (1_430));
            when 10 =>
               pragma Assert (Partial (10, 1) = To_Big_Integer (1_430));
               pragma Assert (Partial (10, 2) = To_Big_Integer (1_859));
               pragma Assert (Partial (10, 3) = To_Big_Integer (2_123));
               pragma Assert (Partial (10, 4) = To_Big_Integer (2_333));
               pragma Assert (Partial (10, 5) = To_Big_Integer (2_529));
               pragma Assert (Partial (10, 6) = To_Big_Integer (2_739));
               pragma Assert (Partial (10, 7) = To_Big_Integer (3_003));
               pragma Assert (Partial (10, 8) = To_Big_Integer (3_432));
               pragma Assert (Partial (10, 9) = To_Big_Integer (4_862));
            when 11 =>
               pragma Assert (Partial (11, 1) = To_Big_Integer (4_862));
               pragma Assert (Partial (11, 2) = To_Big_Integer (6_292));
               pragma Assert (Partial (11, 3) = To_Big_Integer (7_150));
               pragma Assert (Partial (11, 4) = To_Big_Integer (7_810));
               pragma Assert (Partial (11, 5) = To_Big_Integer (8_398));
               pragma Assert (Partial (11, 6) = To_Big_Integer (8_986));
               pragma Assert (Partial (11, 7) = To_Big_Integer (9_646));
               pragma Assert (Partial (11, 8) = To_Big_Integer (10_504));
               pragma Assert (Partial (11, 9) = To_Big_Integer (11_934));
               pragma Assert (Partial (11, 10) = To_Big_Integer (16_796));
            when 12 =>
               pragma Assert (Partial (12, 1) = To_Big_Integer (16_796));
               pragma Assert (Partial (12, 2) = To_Big_Integer (21_658));
               pragma Assert (Partial (12, 3) = To_Big_Integer (24_518));
               pragma Assert (Partial (12, 4) = To_Big_Integer (26_663));
               pragma Assert (Partial (12, 5) = To_Big_Integer (28_511));
               pragma Assert (Partial (12, 6) = To_Big_Integer (30_275));
               pragma Assert (Partial (12, 7) = To_Big_Integer (32_123));
               pragma Assert (Partial (12, 8) = To_Big_Integer (34_268));
               pragma Assert (Partial (12, 9) = To_Big_Integer (37_128));
               pragma Assert (Partial (12, 10) = To_Big_Integer (41_990));
               pragma Assert (Partial (12, 11) = To_Big_Integer (58_786));
            when 13 =>
               pragma Assert (Partial (13, 1) = To_Big_Integer (58_786));
               pragma Assert (Partial (13, 2) = To_Big_Integer (75_582));
               pragma Assert (Partial (13, 3) = To_Big_Integer (85_306));
               pragma Assert (Partial (13, 4) = To_Big_Integer (92_456));
               pragma Assert (Partial (13, 5) = To_Big_Integer (98_462));
               pragma Assert (Partial (13, 6) = To_Big_Integer (104_006));
               pragma Assert (Partial (13, 7) = To_Big_Integer (109_550));
               pragma Assert (Partial (13, 8) = To_Big_Integer (115_556));
               pragma Assert (Partial (13, 9) = To_Big_Integer (122_706));
               pragma Assert (Partial (13, 10) = To_Big_Integer (132_430));
               pragma Assert (Partial (13, 11) = To_Big_Integer (149_226));
               pragma Assert (Partial (13, 12) = To_Big_Integer (208_012));
            when 14 =>
               pragma Assert (Partial (14, 1) = To_Big_Integer (208_012));
               pragma Assert (Partial (14, 2) = To_Big_Integer (266_798));
               pragma Assert (Partial (14, 3) = To_Big_Integer (300_390));
               pragma Assert (Partial (14, 4) = To_Big_Integer (324_700));
               pragma Assert (Partial (14, 5) = To_Big_Integer (344_720));
               pragma Assert (Partial (14, 6) = To_Big_Integer (362_738));
               pragma Assert (Partial (14, 7) = To_Big_Integer (380_162));
               pragma Assert (Partial (14, 8) = To_Big_Integer (398_180));
               pragma Assert (Partial (14, 9) = To_Big_Integer (418_200));
               pragma Assert (Partial (14, 10) = To_Big_Integer (442_510));
               pragma Assert (Partial (14, 11) = To_Big_Integer (476_102));
               pragma Assert (Partial (14, 12) = To_Big_Integer (534_888));
               pragma Assert (Partial (14, 13) = To_Big_Integer (742_900));
            when 15 =>
               pragma Assert (Partial (15, 1) = To_Big_Integer (742_900));
               pragma Assert (Partial (15, 2) = To_Big_Integer (950_912));
               pragma Assert (Partial (15, 3) = To_Big_Integer (1_068_484));
               pragma Assert (Partial (15, 4) = To_Big_Integer (1_152_464));
               pragma Assert (Partial (15, 5) = To_Big_Integer (1_220_532));
               pragma Assert (Partial (15, 6) = To_Big_Integer (1_280_592));
               pragma Assert (Partial (15, 7) = To_Big_Integer (1_337_220));
               pragma Assert (Partial (15, 8) = To_Big_Integer (1_393_848));
               pragma Assert (Partial (15, 9) = To_Big_Integer (1_453_908));
               pragma Assert (Partial (15, 10) = To_Big_Integer (1_521_976));
               pragma Assert (Partial (15, 11) = To_Big_Integer (1_605_956));
               pragma Assert (Partial (15, 12) = To_Big_Integer (1_723_528));
               pragma Assert (Partial (15, 13) = To_Big_Integer (1_931_540));
               pragma Assert (Partial (15, 14) = To_Big_Integer (2_674_440));
            when 16 =>
               pragma Assert (Partial (16, 1) = To_Big_Integer (2_674_440));
               pragma Assert (Partial (16, 2) = To_Big_Integer (3_417_340));
               pragma Assert (Partial (16, 3) = To_Big_Integer (3_833_364));
               pragma Assert (Partial (16, 4) = To_Big_Integer (4_127_294));
               pragma Assert (Partial (16, 5) = To_Big_Integer (4_362_438));
               pragma Assert (Partial (16, 6) = To_Big_Integer (4_566_642));
               pragma Assert (Partial (16, 7) = To_Big_Integer (4_755_402));
               pragma Assert (Partial (16, 8) = To_Big_Integer (4_939_443));
               pragma Assert (Partial (16, 9) = To_Big_Integer (5_128_203));
               pragma Assert (Partial (16, 10) = To_Big_Integer (5_332_407));
               pragma Assert (Partial (16, 11) = To_Big_Integer (5_567_551));
               pragma Assert (Partial (16, 12) = To_Big_Integer (5_861_481));
               pragma Assert (Partial (16, 13) = To_Big_Integer (6_277_505));
               pragma Assert (Partial (16, 14) = To_Big_Integer (7_020_405));
               pragma Assert (Partial (16, 15) = To_Big_Integer (9_694_845));
            when 17 =>
               pragma Assert (Partial (17, 1) = To_Big_Integer (9_694_845));
               pragma Assert (Partial (17, 2) = To_Big_Integer (12_369_285));
               pragma Assert (Partial (17, 3) = To_Big_Integer (13_855_085));
               pragma Assert (Partial (17, 4) = To_Big_Integer (14_895_145));
               pragma Assert (Partial (17, 5) = To_Big_Integer (15_718_149));
               pragma Assert (Partial (17, 6) = To_Big_Integer (16_423_581));
               pragma Assert (Partial (17, 7) = To_Big_Integer (17_065_365));
               pragma Assert (Partial (17, 8) = To_Big_Integer (17_678_835));
               pragma Assert (Partial (17, 9) = To_Big_Integer (18_292_305));
               pragma Assert (Partial (17, 10) = To_Big_Integer (18_934_089));
               pragma Assert (Partial (17, 11) = To_Big_Integer (19_639_521));
               pragma Assert (Partial (17, 12) = To_Big_Integer (20_462_525));
               pragma Assert (Partial (17, 13) = To_Big_Integer (21_502_585));
               pragma Assert (Partial (17, 14) = To_Big_Integer (22_988_385));
               pragma Assert (Partial (17, 15) = To_Big_Integer (25_662_825));
               pragma Assert (Partial (17, 16) = To_Big_Integer (35_357_670));
            when 18 =>
               pragma Assert (Partial (18, 1) = To_Big_Integer (35_357_670));
               pragma Assert (Partial (18, 2) = To_Big_Integer (45_052_515));
               pragma Assert (Partial (18, 3) = To_Big_Integer (50_401_395));
               pragma Assert (Partial (18, 4) = To_Big_Integer (54_115_895));
               pragma Assert (Partial (18, 5) = To_Big_Integer (57_028_063));
               pragma Assert (Partial (18, 6) = To_Big_Integer (59_497_075));
               pragma Assert (Partial (18, 7) = To_Big_Integer (61_714_147));
               pragma Assert (Partial (18, 8) = To_Big_Integer (63_799_945));
               pragma Assert (Partial (18, 9) = To_Big_Integer (65_844_845));
               pragma Assert (Partial (18, 10) = To_Big_Integer (67_930_643));
               pragma Assert (Partial (18, 11) = To_Big_Integer (70_147_715));
               pragma Assert (Partial (18, 12) = To_Big_Integer (72_616_727));
               pragma Assert (Partial (18, 13) = To_Big_Integer (75_528_895));
               pragma Assert (Partial (18, 14) = To_Big_Integer (79_243_395));
               pragma Assert (Partial (18, 15) = To_Big_Integer (84_592_275));
               pragma Assert (Partial (18, 16) = To_Big_Integer (94_287_120));
               pragma Assert (Partial (18, 17) = To_Big_Integer (129_644_790));
            when 19 =>
               pragma Assert (Partial (19, 1) = To_Big_Integer (129_644_790));
               pragma Assert (Partial (19, 2) = To_Big_Integer (165_002_460));
               pragma Assert (Partial (19, 3) = To_Big_Integer (184_392_150));
               pragma Assert (Partial (19, 4) = To_Big_Integer (197_764_350));
               pragma Assert (Partial (19, 5) = To_Big_Integer (208_164_950));
               pragma Assert (Partial (19, 6) = To_Big_Integer (216_901_454));
               pragma Assert (Partial (19, 7) = To_Big_Integer (224_661_206));
               pragma Assert (Partial (19, 8) = To_Big_Integer (231_866_690));
               pragma Assert (Partial (19, 9) = To_Big_Integer (238_819_350));
               pragma Assert (Partial (19, 10) = To_Big_Integer (245_772_010));
               pragma Assert (Partial (19, 11) = To_Big_Integer (252_977_494));
               pragma Assert (Partial (19, 12) = To_Big_Integer (260_737_246));
               pragma Assert (Partial (19, 13) = To_Big_Integer (269_473_750));
               pragma Assert (Partial (19, 14) = To_Big_Integer (279_874_350));
               pragma Assert (Partial (19, 15) = To_Big_Integer (293_246_550));
               pragma Assert (Partial (19, 16) = To_Big_Integer (312_636_240));
               pragma Assert (Partial (19, 17) = To_Big_Integer (347_993_910));
               pragma Assert (Partial (19, 18) = To_Big_Integer (477_638_700));
            when 20 =>
               pragma Assert (Partial (20, 1) = To_Big_Integer (477_638_700));
               pragma Assert (Partial (20, 2) = To_Big_Integer (607_283_490));
               pragma Assert (Partial (20, 3) = To_Big_Integer (677_998_830));
               pragma Assert (Partial (20, 4) = To_Big_Integer (726_473_055));
               pragma Assert (Partial (20, 5) = To_Big_Integer (763_915_215));
               pragma Assert (Partial (20, 6) = To_Big_Integer (795_117_015));
               pragma Assert (Partial (20, 7) = To_Big_Integer (822_574_599));
               pragma Assert (Partial (20, 8) = To_Big_Integer (847_793_793));
               pragma Assert (Partial (20, 9) = To_Big_Integer (871_812_073));
               pragma Assert (Partial (20, 10) = To_Big_Integer (895_451_117));
               pragma Assert (Partial (20, 11) = To_Big_Integer (919_469_397));
               pragma Assert (Partial (20, 12) = To_Big_Integer (944_688_591));
               pragma Assert (Partial (20, 13) = To_Big_Integer (972_146_175));
               pragma Assert (Partial (20, 14) = To_Big_Integer (1_003_347_975));
               pragma Assert (Partial (20, 15) = To_Big_Integer (1_040_790_135));
               pragma Assert (Partial (20, 16) = To_Big_Integer (1_089_264_360));
               pragma Assert (Partial (20, 17) = To_Big_Integer (1_159_979_700));
               pragma Assert (Partial (20, 18) = To_Big_Integer (1_289_624_490));
               pragma Assert (Partial (20, 19) = To_Big_Integer (1_767_263_190));
         end case;
      end Lemma_Ways_Step;

      procedure Lemma_Partial_Le (N : Positive; S : Natural) is
      begin
         if S < N - 1 then
            Lemma_Partial_Le (N, S + 1);
            pragma Assert (Ways (S + 1) * Ways (N - S - 1) >= 0);
         end if;
      end Lemma_Partial_Le;

      procedure Lemma_Mul_Mono (X, XX, Y, YY : Big_Integer) is
      begin
         pragma Assert (X * Y <= XX * Y);
         pragma Assert (XX * Y <= XX * YY);
      end Lemma_Mul_Mono;

      procedure Lemma_Bound_Mul (P, L : Positive) is null;

      procedure Lemma_Count (L : Positive) is null;
   end Lemmas;

   use Lemmas;

   function Number_Of_Ways (Operands : Operand_Count) return Positive is
      type Big_Table is array (1 .. Max_Operands) of Big_Integer;
      W : Big_Table := [others => To_Big_Integer (1)];
   begin
      declare
         pragma Assertion_Policy (Ghost => Ignore);
      begin
         Lemma_Ways_Step (1);
      end;
      for M in 2 .. Operands loop
         pragma Loop_Invariant (for all I in 1 .. M - 1 => W (I) = Ways (I));
         declare
            Acc : Big_Integer := To_Big_Integer (0);
         begin
            for K in 1 .. M - 1 loop
               pragma Loop_Invariant (for all I in 1 .. M - 1 => W (I) = Ways (I));
               pragma Loop_Invariant (Acc = Partial (M, K - 1));
               declare
                  Term : constant Big_Integer := W (K) * W (M - K);
               begin
                  pragma Assert (Term = Ways (K) * Ways (M - K));
                  pragma Assert (Partial (M, K) = Partial (M, K - 1) + Term);
                  Acc := Acc + Term;
               end;
            end loop;
            declare
               pragma Assertion_Policy (Ghost => Ignore);
            begin
               Lemma_Ways_Step (M);
            end;
            W (M) := Acc;
         end;
      end loop;
      declare
         pragma Assertion_Policy (Ghost => Ignore);
      begin
         Lemma_Ways_Step (Operands);
      end;
      return To_Integer (W (Operands));
   end Number_Of_Ways;

   --  A op B, with A a result of P operands and B one of L - P operands.
   function Apply (Op : Operator; A, B : Long_Long_Integer; P, L : Positive) return Long_Long_Integer
   with
     Global => null,
     Pre    => L <= Max_Expression and then P < L
               and then A in -Bound (P) .. Bound (P) and then B in -Bound (L - P) .. Bound (L - P),
     Post   => Apply'Result in -Bound (L) .. Bound (L);

   function Apply (Op : Operator; A, B : Long_Long_Integer; P, L : Positive) return Long_Long_Integer is
      BP : constant Big_Integer := Big (Bound (P)) with Ghost;
      BQ : constant Big_Integer := Big (Bound (L - P)) with Ghost;
   begin
      declare
         pragma Assertion_Policy (Ghost => Ignore);
      begin
         Lemma_Bound_Mul (P, L);
         Lemma_Mul_Mono (Big (abs A), BP, Big (abs B), BQ);
         Lemma_Mul_Mono (To_Big_Integer (2), BP, BQ, BQ);
         Lemma_Mul_Mono (BP, BP, To_Big_Integer (2), BQ);
      end;
      case Op is
         when Plus =>
            return A + B;
         when Minus =>
            return A - B;
         when Times =>
            pragma Assert (abs (Big (A) * Big (B)) = Big (abs A) * Big (abs B));
            return A * B;
      end case;
   end Apply;

   --  The element subtype carries the overall bound for every entry; the
   --  per-length bound is stated only for the entries Sub defines.
   type Slot is array (1 .. Max_Results) of Result_Value;

   --  The results of the L operands Values (I .. I + L - 1), in
   --  Sub (...) (1 .. Count (L)); the unused entries are 0.
   function Sub (Values : Operand_List; Ops : Operator_List; I, L : Positive) return Slot
   with
     Global             => null,
     Pre                => Values'First = 1 and then Values'Length <= Max_Expression
                           and then Ops'First = 1 and then Ops'Length = Values'Length - 1
                           and then L <= Values'Length and then I <= Values'Length - L + 1,
     Post               => (for all M in 1 .. Count (L) => Sub'Result (M) in -Bound (L) .. Bound (L)),
     Subprogram_Variant => (Decreases => L);

   function Sub (Values : Operand_List; Ops : Operator_List; I, L : Positive) return Slot is
      --  The element subtype carries the bound, so no loop invariant has to
      --  restate it for all Max_Results entries (which would also be checked
      --  at every iteration with assertions enabled).
      subtype Value_L is Long_Long_Integer range -Bound (L) .. Bound (L);
      type Slot_L is array (1 .. Max_Results) of Value_L;
      Cur : Slot_L := [others => 0];
      P   : Natural := 0;
   begin
      if L = 1 then
         Cur (1) := Long_Long_Integer (Values (I));
         return [for M in 1 .. Max_Results => Cur (M)];
      end if;
      declare
         pragma Assertion_Policy (Ghost => Ignore);
      begin
         Lemma_Ways_Step (L);
         Lemma_Count (L);
      end;
      --  The last operator applied is Ops (I + S - 1): S operands on its left.
      for S in 1 .. L - 1 loop
         pragma Loop_Invariant (To_Big_Integer (P) = Partial (L, S - 1));
         declare
            pragma Assertion_Policy (Ghost => Ignore);
         begin
            Lemma_Partial_Le (L, S);
            Lemma_Count (S);
            Lemma_Count (L - S);
         end;
         declare
            Left  : constant Slot := Sub (Values, Ops, I, S);
            Right : constant Slot := Sub (Values, Ops, I + S, L - S);
            LL    : constant Positive := Count (S);
            LR    : constant Positive := Count (L - S);
            Term  : constant Big_Integer := To_Big_Integer (LL) * To_Big_Integer (LR) with Ghost;
            Base  : constant Big_Integer := Partial (L, S - 1) with Ghost;
         begin
            pragma Assert (Term = Ways (S) * Ways (L - S));
            pragma Assert (Partial (L, S) = Base + Term);
            for A in 1 .. LL loop
               pragma Loop_Invariant
                 (To_Big_Integer (P) = Base + To_Big_Integer (A - 1) * To_Big_Integer (LR));
               declare
                  pragma Assertion_Policy (Ghost => Ignore);
               begin
                  Lemma_Mul_Mono (To_Big_Integer (A), To_Big_Integer (LL),
                                  To_Big_Integer (LR), To_Big_Integer (LR));
               end;
               for B in 1 .. LR loop
                  pragma Loop_Invariant
                    (To_Big_Integer (P) = Base
                       + To_Big_Integer (A - 1) * To_Big_Integer (LR) + To_Big_Integer (B - 1));
                  P := P + 1;
                  Cur (P) := Apply (Ops (I + S - 1), Left (A), Right (B), S, L);
               end loop;
            end loop;
         end;
      end loop;
      return [for M in 1 .. Max_Results => Cur (M)];
   end Sub;

   function All_Results (Values : Operand_List; Ops : Operator_List) return Value_List is
      N   : constant Positive := Values'Length;
      --  Sub works on origin 1: copy (slide) both lists there.
      V1  : constant Operand_List (1 .. N) := Values;
      O1  : constant Operator_List (1 .. N - 1) := Ops;
      All_Of : constant Slot := Sub (V1, O1, 1, N);
   begin
      declare
         pragma Assertion_Policy (Ghost => Ignore);
      begin
         Lemma_Count (N);
      end;
      return Value_List (All_Of (1 .. Count (N)));
   end All_Results;
end Different_Ways_Parentheses;
