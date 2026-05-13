declare namespace LuaUIInterop {
  type LuaMap<TValue = unknown> = Record<string, TValue>;
  type LuaFunction<TArgs extends unknown[] = unknown[], TResult = unknown> = (
    this: void,
    ...args: TArgs
  ) => TResult;

  namespace Rule {
    type ValueOf<TRule> = TRule extends Descriptor<infer TValue>
      ? TValue
      : never;

    interface BaseOptions<TValue = unknown> {
      optional?: boolean;
      default?: TValue;
    }

    interface Descriptor<TValue = unknown> {
      readonly kind: string;
      readonly optional: boolean;
      readonly has_default: boolean;
      readonly default: TValue | undefined;
    }

    interface StringOptions extends BaseOptions<string> {
      non_empty?: boolean;
      min_len?: number;
      max_len?: number;
      pattern?: string;
    }

    interface StringDescriptor extends Descriptor<string> {
      readonly kind: "string";
      readonly non_empty?: boolean;
      readonly min_len?: number;
      readonly max_len?: number;
      readonly pattern?: string;
    }

    interface NumberOptions extends BaseOptions<number> {
      min?: number;
      max?: number;
      integer?: boolean;
      finite?: boolean;
    }

    interface NumberDescriptor extends Descriptor<number> {
      readonly kind: "number";
      readonly min?: number;
      readonly max?: number;
      readonly integer: boolean;
      readonly finite: boolean;
    }

    interface BooleanOptions extends BaseOptions<boolean> {}

    interface BooleanDescriptor extends Descriptor<boolean> {
      readonly kind: "boolean";
    }

    interface TableOptions<
      TItem = unknown,
      TTable extends object = LuaMap<TItem>
    > extends BaseOptions<TTable> {
      items?: Descriptor<TItem>;
    }

    interface TableDescriptor<
      TItem = unknown,
      TTable extends object = LuaMap<TItem>
    > extends Descriptor<TTable> {
      readonly kind: "table";
      readonly items?: Descriptor<TItem>;
    }

    interface FunctionDescriptor<
      TFunction extends LuaFunction = LuaFunction
    > extends Descriptor<TFunction> {
      readonly kind: "func";
    }

    interface EnumDescriptor<
      TValue extends LuaUILibrary.Atom = LuaUILibrary.Atom
    > extends Descriptor<TValue> {
      readonly kind: "enum";
      readonly display: string;
    }

    interface LiteralDescriptor<TValue> extends Descriptor<TValue> {
      readonly kind: "literal";
      readonly value: TValue;
      readonly display: string;
    }

    interface InstanceDescriptor<TClass extends object = object>
      extends Descriptor<object> {
      readonly kind: "instance";
      readonly class: TClass;
      readonly class_name: string;
    }

    type CustomValidator<TValue = unknown> = (
      this: void,
      name: string,
      value: TValue,
      level: number
    ) => void;

    interface CustomDescriptor<TValue = unknown> extends Descriptor<TValue> {
      readonly kind: "custom";
      readonly fn: CustomValidator<TValue>;
    }

    interface CompositeDescriptor<TValue = unknown>
      extends Descriptor<TValue> {
      readonly kind: "any_of" | "all_of";
      readonly rules: readonly Descriptor<unknown>[];
    }

    interface Module {
      string(this: void, opts?: StringOptions): StringDescriptor;
      number(this: void, opts?: NumberOptions): NumberDescriptor;
      boolean(
        this: void,
        opts?: BooleanOptions | boolean
      ): BooleanDescriptor;
      table<TItem = unknown, TTable extends object = LuaMap<TItem>>(
        this: void,
        opts?: TableOptions<TItem, TTable>
      ): TableDescriptor<TItem, TTable>;
      func<TFunction extends LuaFunction = LuaFunction>(
        this: void,
        opts?: BaseOptions<TFunction>
      ): FunctionDescriptor<TFunction>;
      enum<TValue extends LuaUILibrary.Atom>(
        this: void,
        values: readonly TValue[],
        opts?: BaseOptions<TValue>
      ): EnumDescriptor<TValue>;
      literal<TValue>(
        this: void,
        value: Exclude<TValue, undefined>,
        opts?: BaseOptions<Exclude<TValue, undefined>>
      ): LiteralDescriptor<Exclude<TValue, undefined>>;
      instance<TClass extends object = object>(
        this: void,
        classRef: TClass,
        className: string,
        opts?: BaseOptions<object>
      ): InstanceDescriptor<TClass>;
      custom<TValue = unknown>(
        this: void,
        fn: CustomValidator<TValue>,
        opts?: BaseOptions<TValue>
      ): CustomDescriptor<TValue>;
      optional<TRule extends Descriptor<unknown>>(
        this: void,
        rule: TRule
      ): TRule & {
        readonly optional: true;
        readonly has_default: false;
        readonly default: undefined;
      };
      any_of<TRules extends readonly Descriptor<unknown>[]>(
        this: void,
        rules: TRules,
        opts?: BaseOptions<ValueOf<TRules[number]>>
      ): CompositeDescriptor<ValueOf<TRules[number]>>;
      all_of<TRules extends readonly Descriptor<unknown>[]>(
        this: void,
        rules: TRules,
        opts?: BaseOptions<ValueOf<TRules[number]>>
      ): CompositeDescriptor<ValueOf<TRules[number]>>;
      validate<TValue>(
        this: void,
        rule: Descriptor<TValue>,
        name: string,
        value: TValue | undefined
      ): void;
      resolve<TValue>(
        this: void,
        rule: Descriptor<TValue>,
        value: TValue | undefined
      ): LuaMultiReturn<[TValue | undefined, string | undefined]>;
    }
  }

  namespace Schema {
    type RuleMap = LuaMap<Rule.Descriptor<unknown>>;

    interface Instance<TRules extends RuleMap = RuleMap> {
      get_rules(): Readonly<TRules>;
      get_rule<TKey extends keyof TRules & string>(
        property: TKey
      ): TRules[TKey];
      get_rule(property: string): Rule.Descriptor<unknown> | undefined;
      validate_rule(property: keyof TRules & string, target: object): void;
      validate_rule(property: string, target: object): void;
      validate_all(target: object): void;
      set_defaults(target: object, force?: boolean): void;
    }

    interface Module {
      create<TRules extends RuleMap = RuleMap>(
        this: void,
        rules?: TRules
      ): Instance<TRules>;
      extend<
        TBaseRules extends RuleMap,
        TOverrideRules extends RuleMap = {}
      >(
        this: void,
        base: Instance<TBaseRules>,
        overrides?: TOverrideRules
      ): Instance<Omit<TBaseRules, keyof TOverrideRules> & TOverrideRules>;
    }
  }

  namespace DirtyProps {
    interface Definition<TValue = unknown> {
      val: TValue;
      groups?: readonly string[];
    }

    type DefinitionMap = LuaMap<Definition<unknown>>;

    type Values<TDefinitions extends DefinitionMap> = {
      [TKey in keyof TDefinitions]: TDefinitions[TKey] extends Definition<
        infer TValue
      >
        ? TValue
        : never;
    };

    interface Instance {
      sync_dirty_props(): void;
      reset_dirty_props(): this;
      mark_dirty(...groups: string[]): this;
      clear_dirty(...groups: string[]): this;
      is_dirty(key: string): boolean;
      any_dirty(...keys: string[]): boolean;
      all_dirty(...keys: string[]): boolean;
      group_dirty(name: string): boolean;
      group_any_dirty(...groups: string[]): boolean;
      group_all_dirty(...groups: string[]): boolean;
      get_dirty_props(): LuaMap<boolean>;
      get_dirty_groups(): LuaMap<boolean>;
    }

    type Object<TDefinitions extends DefinitionMap> =
      Instance & Values<TDefinitions>;

    interface Module {
      create<TDefinitions extends DefinitionMap>(
        this: void,
        definitions: TDefinitions
      ): Object<TDefinitions>;
      init<TObject extends object, TDefinitions extends DefinitionMap>(
        this: void,
        obj: TObject,
        definitions: TDefinitions
      ): asserts obj is TObject & Object<TDefinitions>;
    }
  }

  namespace Reactive {
    type Getter<TObject extends object, TValue> = (
      this: void,
      self: TObject,
      value: TValue
    ) => TValue;

    type Setter<TObject extends object, TValue> = (
      this: void,
      self: TObject,
      value: TValue,
      oldValue: TValue
    ) => TValue;

    interface Definition<TValue = unknown, TObject extends object = object> {
      val: TValue;
      get?: Getter<TObject, TValue>;
      set?: Setter<TObject, TValue>;
    }

    type DefinitionMap = LuaMap<Definition<unknown, object>>;

    type Values<TDefinitions extends DefinitionMap> = {
      [TKey in keyof TDefinitions]: TDefinitions[TKey] extends Definition<
        infer TValue,
        object
      >
        ? TValue
        : never;
    };

    interface Module {
      create<TDefinitions extends DefinitionMap>(
        this: void,
        definitions: TDefinitions
      ): Values<TDefinitions>;
      define_property<TObject extends object, TKey extends string, TValue>(
        this: void,
        obj: TObject,
        key: TKey,
        def: Definition<TValue, TObject & Record<TKey, TValue>>
      ): asserts obj is TObject & Record<TKey, TValue>;
      remove_property(this: void, obj: object, key: string): void;
      raw_get<TObject extends object, TKey extends keyof TObject & string>(
        this: void,
        obj: TObject,
        key: TKey
      ): TObject[TKey] | undefined;
      raw_get<TValue = unknown>(
        this: void,
        obj: object,
        key: string
      ): TValue | undefined;
      raw_set<TObject extends object, TKey extends keyof TObject & string>(
        this: void,
        obj: TObject,
        key: TKey,
        value: Exclude<TObject[TKey], undefined>
      ): void;
      raw_set<TValue>(
        this: void,
        obj: object,
        key: string,
        value: Exclude<TValue, undefined>
      ): void;
    }
  }

  namespace Memoize {
    interface Module {
      memoize<TArg, TResult>(
        this: void,
        fn: LuaFunction<[TArg], TResult>,
        n?: 1
      ): LuaFunction<[TArg], TResult>;
      memoize<TArgA, TArgB, TResult>(
        this: void,
        fn: LuaFunction<[TArgA, TArgB], TResult>,
        n: 2
      ): LuaFunction<[TArgA, TArgB], TResult>;
      memoize<TArgA, TArgB, TArgC, TResult>(
        this: void,
        fn: LuaFunction<[TArgA, TArgB, TArgC], TResult>,
        n: 3
      ): LuaFunction<[TArgA, TArgB, TArgC], TResult>;
    }
  }
}

declare module "lib.ui.utils.rule" {
  const Rule: LuaUIInterop.Rule.Module;
  export = Rule;
}

declare module "lib.ui.utils.schema" {
  const Schema: LuaUIInterop.Schema.Module;
  export = Schema;
}

declare module "lib.ui.utils.dirty_props" {
  const DirtyProps: LuaUIInterop.DirtyProps.Module;
  export = DirtyProps;
}

declare module "lib.ui.utils.reactive" {
  const Reactive: LuaUIInterop.Reactive.Module;
  export = Reactive;
}

declare module "lib.ui.utils.memoize" {
  const Memoize: LuaUIInterop.Memoize.Module;
  export = Memoize;
}
