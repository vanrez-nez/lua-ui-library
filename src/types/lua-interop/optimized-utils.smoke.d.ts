import DirtyProps = require("lib.ui.utils.dirty_props");
import Memoize = require("lib.ui.utils.memoize");
import Reactive = require("lib.ui.utils.reactive");
import Rule = require("lib.ui.utils.rule");
import Schema = require("lib.ui.utils.schema");

type Expect<T extends true> = T;
type Equal<TLeft, TRight> = (<T>() => T extends TLeft ? 1 : 2) extends <
  T
>() => T extends TRight ? 1 : 2
  ? true
  : false;

declare const stringRule: ReturnType<typeof Rule.string>;
declare const resolvedString: ReturnType<typeof Rule.resolve<string>>;
declare const schema: ReturnType<
  typeof Schema.create<{ label: typeof stringRule }>
>;
declare const dirty: ReturnType<
  typeof DirtyProps.create<{ x: { val: number; groups: string[] } }>
>;
declare const reactive: ReturnType<
  typeof Reactive.create<{ count: { val: number } }>
>;
declare const memoized: ReturnType<typeof Memoize.memoize<string, number>>;

type SmokeRule = Expect<Equal<typeof stringRule.kind, "string">>;
type SmokeResolve = Expect<
  Equal<typeof resolvedString, LuaMultiReturn<[string | undefined, string | undefined]>>
>;
type SmokeSchema = Expect<
  Equal<ReturnType<typeof schema.get_rule>, LuaUIInterop.Rule.Descriptor<unknown> | undefined>
>;
type SmokeDirty = Expect<Equal<typeof dirty.x, number>>;
type SmokeReactive = Expect<Equal<typeof reactive.count, number>>;
type SmokeMemoize = Expect<Equal<typeof memoized, LuaUIInterop.LuaFunction<[string], number>>>;
