# UI Styling Specification

> Version `0.1.0` — initial publication. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

## 3. Glossary

All terminology defined in [UI Foundation Specification](./ui-foundation-spec.md), [UI Graphics Specification](./ui-graphics-spec.md), and [UI Motion Specification](./ui-motion-spec.md) is binding in this document.

`Styled root`: A `Drawable` root that exposes styling properties defined by this document. `Drawable` is defined in [UI Foundation Specification](./ui-foundation-spec.md); this document uses it only as a styling carrier.

`Named presentational part`: A documented stable visual part such as `surface`, `backdrop`, `track`, or `indicator` that may expose styling properties defined by this document. Which named parts exist and whether a given part accepts styling is determined by the owning component contract, as defined in [UI Foundation Specification](./ui-foundation-spec.md) and [UI Controls Specification](./ui-controls-spec.md).

`Styling property`: A documented public visual property that affects how a retained node or named visual part is painted, such as a background, border, radius, shadow, or opacity input.

`Resolved styling`: The final paint-ready styling state after direct property overrides, skin inputs, token inputs, defaults, and documented coercions have been applied.

`Background source`: The single background input selected for one node or part in this revision. A background source may be absent, color-backed, gradient-backed, or image-backed.

`Gradient`: A resolved color-interpolation background source.

`Image-backed background`: A background source that paints a graphics-backed image or texture input according to the styling placement rules defined in this document.

`Border`: The stroke-like visual edge drawn around a node or part according to the documented width, color, opacity, join, pattern, and radius rules.

`Corner radius`: The rounding definition applied per corner to the node or part border and background geometry.

`Shadow`: An outer visual shadow cast outside the node or part bounds.

`Inset shadow`: A visual shadow cast inward from the node or part border toward its content region.

`Color input`: Any accepted public color value form that resolves to an RGBA result.

`Skin` and `Token` have the meanings defined in [UI Foundation Specification](./ui-foundation-spec.md). This document uses those terms only through that binding definition.

## 4. Scope And Domain

This document defines the public styling contract for retained nodes and named presentational parts in the UI library.

This revision owns:

- styling property definitions
- styling value forms
- color input acceptance and conversion behavior
- background-source types
- border styling
- corner-radius styling
- shadow and inset-shadow styling
- styling precedence and resolution
- styling failure semantics
- styling references to graphics-backed image sources
- the set of styling properties that are motion-capable

This revision does not own:

- graphics object contracts such as `Texture`, `Sprite`, `Atlas`, or `Image`
- motion timing, interpolation, adapter, or phase semantics
- component anatomy or which named parts exist on a given control

Responsibility boundary:

- this document defines what a styling property means
- [UI Foundation Specification](./ui-foundation-spec.md) and [UI Controls Specification](./ui-controls-spec.md) define which components and parts expose those properties
- [UI Graphics Specification](./ui-graphics-spec.md) defines graphics-backed source objects referenced by image-backed styling inputs
- [UI Motion Specification](./ui-motion-spec.md) defines how documented motion-capable styling properties animate over time

No other specification in this set may partially redefine the fundamentals owned by this document. Other specifications may only reference this document when they need styling behavior.

## 4A. Styling Ownership Model

The styling system exists to provide one authoritative definition of shared visual paint behavior across:

- `Drawable`
- `Drawable` descendants
- named control parts such as `surface`, `backdrop`, `track`, `indicator`, `field`, and `panel`

This document does not reduce styling to the broader term `surface`. A surface may expose styling, but styling itself is the owned concept here.

The root styling carrier in the inheritance hierarchy is `Drawable`. `Drawable` is defined in [UI Foundation Specification](./ui-foundation-spec.md). This document does not redefine the `Drawable` component contract; it defines only what styling properties `Drawable` carries.

Implications:

- a component that inherits from `Drawable` may expose styling on its root
- a control may additionally expose styling on documented named parts
- when a control references background, border, radius, shadow, color-like paint inputs, or similar fundamentals, those definitions come from this document

## 4B. Styling Resolution Model

Styling resolution is field-by-field and deterministic.

The precedence order in this revision is:

1. direct styling property on the instance
2. resolved skin value for the same styling property
3. active token or theme-provided fallback used by that skin or component contract
4. library default fallback when documented

Field-by-field resolution means:

- if a direct property is present, it overrides the skin for that same property only
- the skin remains authoritative for every styling property not explicitly overridden by a direct property
- unresolved properties may continue falling through to token-backed or library-backed defaults

This document defines the property semantics. Skin contracts remain valid, but skins are one styling input source rather than the authority for styling meaning.

This is the styling-property view of the visual resolution cascade. The full resolution order, including variant-specific and base-level skin override granularity, is defined in [UI Foundation Specification](./ui-foundation-spec.md) §8.3.

## 4C. Styling Carriers

### 4C.1 Root Carriers

`Drawable` is the base styling carrier in this revision.

The root of a `Drawable` may expose:

- one background source
- border styling
- per-corner radius styling
- shadow styling
- inset-shadow styling
- styling opacities defined in this document

### 4C.2 Named Part Carriers

A documented named presentational part may expose any styling property defined by this document when the owning component contract says that part is styleable.

Examples:

- `Modal.backdrop`
- `Button.surface`
- `ProgressBar.indicator`
- `Tooltip.surface`

This document defines what those styling properties mean. The owning component document defines whether a given part exists and whether that part accepts a given styling property.

## 5. Value Forms And Parsing

## 5.1 Scalar And Length Inputs

Unless a property defines a narrower domain, scalar styling inputs in this revision are numeric.

Negative values are invalid where the property describes a size, width, blur amount, radius, or opacity domain that cannot be negative.

Quad-like styling families in this revision may additionally use the shared
normalization contracts defined in [UI Foundation Specification](./ui-foundation-spec.md):

- `SideQuad input`
- `CornerQuad input`

## 5.2 Opacity Inputs

The opacity domain is numeric and closed to the inclusive range `[0, 1]`.

Opacity may appear:

- as part of a color input
- as an independent styling property when a source type requires opacity independent of color, such as image-backed backgrounds, shader-backed presentation, borders, shadows, or other non-color paint sources

Opacity values outside `[0, 1]` are invalid and fail deterministically.

## 5.3 Color Inputs

Accepted public color input forms in this revision:

- numeric RGBA
- hex color strings
- a documented small set of named colors
- HSL and HSLA values that resolve through supported conversion into RGBA

The canonical resolved result is RGBA.

The canonical numeric RGBA input form in this revision is a sequential numeric sequence:

- `{ red, green, blue }`
- `{ red, green, blue, alpha }`

Component rules:

- components are numeric
- component values are in the inclusive range `[0, 1]`
- alpha is optional and defaults to `1`

When any component value exceeds `1`, the input is treated as a `[0, 255]` range color through the conversion path defined in §5.4.

This document standardizes the accepted public input forms and the requirement that supported alternative color models or spaces resolve into the same RGBA result domain. It does not standardize one internal color-processing implementation.

Named colors are a supported public color-input form in this revision.

The following names are required and portable:

- `transparent`
- `black`
- `white`

Implementations may support additional named colors. Additional names are
implementation-defined unless a later revision standardizes them explicitly.

## 5.4 Color Conversion

The styling contract permits conversion from supported alternative color models or spaces into RGBA.

This means:

- a consumer may provide a color through a supported non-RGBA form
- the library resolves that input into RGBA before final styling resolution
- conversion behavior is part of the public styling contract

Accepted hex forms in this revision are:

- `#RGB`
- `#RGBA`
- `#RRGGBB`
- `#RRGGBBAA`

Accepted non-RGBA converted forms in this revision are:

- `hsl(...)`
- `hsla(...)`

Accepted HSL and HSLA argument forms are:

- `hsl(hue, saturation, lightness)`
- `hsla(hue, saturation, lightness, alpha)`

Component rules:

- `hue` is numeric and expressed in degrees
- `saturation` is numeric and expressed in the inclusive range `[0, 1]`
- `lightness` is numeric and expressed in the inclusive range `[0, 1]`
- `alpha` is numeric, optional for `hsl(...)`, and expressed in the inclusive range `[0, 1]`

`hue` may be any finite numeric value and resolves by angle wrapping.

Accepted numeric range forms in this revision also include `[0, 255]` scale inputs.

When any component in a numeric RGBA input exceeds `1`, the library treats the entire color as a `[0, 255]` range input and converts it by dividing all components by `255`.

A `[0, 255]` range input is invalid and fails deterministically when:

- any component exceeds `255`
- any component is non-integer — a non-integer value alongside a component greater than `1` indicates mixed-scale input

This document does not require one implementation strategy for those conversions.

## 5.5 Graphics-Backed Source Inputs

When a styling property accepts an image-backed background source, the accepted source types in this revision are `Texture` and `Sprite`, as defined in [UI Graphics Specification](./ui-graphics-spec.md).

`Image` is a retained UI primitive defined in [UI Graphics Specification](./ui-graphics-spec.md) and is not an accepted source for `backgroundImage`. The naming overlap is intentional — `backgroundImage` names the styling property, `Image` names the display component — but they operate at different levels.

This document owns:

- how the styling property references that source
- how the source is placed, repeated, aligned, and offset as a background

This document does not redefine the graphics object contracts themselves.

## 6. Background Contract

## 6.1 Single Background Source Rule

Each styled root or styled part in this revision resolves at most one background source.

That background source may be:

- absent
- color-backed
- gradient-backed
- image-backed

Multiple stacked background layers are not part of this revision.

## 6.2 Background Properties

The flat background property family in this revision is:

- `backgroundColor`
- `backgroundOpacity`
- `backgroundGradient`
- `backgroundImage`
- `backgroundRepeatX`
- `backgroundRepeatY`
- `backgroundOffsetX`
- `backgroundOffsetY`
- `backgroundAlignX`
- `backgroundAlignY`

Only one background-source family may win final resolution for a given node or part.

Source selection rules:

- if `backgroundImage` resolves, the background is image-backed
- else if `backgroundGradient` resolves, the background is gradient-backed
- else if `backgroundColor` resolves, the background is color-backed
- else no background is painted

The owning component may define narrower support, but it must not redefine the meaning of these properties.

## 6.3 Color-Backed Background

`backgroundColor` paints a solid background fill.

`backgroundOpacity` modulates the resolved background result.

When both the color input and the independent opacity input contribute opacity, final background alpha is:

- `resolvedBackgroundAlpha = colorAlpha * backgroundOpacity`

When no background source resolves, `backgroundOpacity` has no effect and is ignored.

## 6.4 Gradient-Backed Background

`backgroundGradient` is part of the first stable contract in this revision.

A gradient-backed background must support:

- a gradient kind
- a direction
- an ordered color list

The stable gradient kinds in this revision are:

- `linear`

`linear` gradients must define:

- `direction`
- `colors`

Accepted `direction` values in this revision are:

- `horizontal`
- `vertical`

The library may implement gradients through any rendering path, such as a mesh-backed or image-backed technique, but the public gradient contract is limited to the direction and color-distribution model standardized here.

This revision does not standardize radial gradients.

This revision does not standardize:

- conic gradients
- arbitrary-angle gradients
- explicit stop-offset inputs

Gradient colors are color inputs governed by this document.

Gradient colors are evenly distributed across the painted background box in the resolved direction.

A valid gradient in this revision must define at least two colors.

`backgroundOpacity` applies to gradients after gradient color resolution.

Final gradient alpha is:

- `resolvedPixelAlpha = interpolatedGradientAlpha(x, y) * backgroundOpacity`

Invalid gradient definitions fail deterministically.

## 6.5 Image-Backed Background

`backgroundImage` accepts a `Texture` or `Sprite` source as defined in [UI Graphics Specification](./ui-graphics-spec.md). The `Image` retained primitive is a display component, not a pixel source, and is not a valid value for this property.

The flat placement and repetition fields are:

- `backgroundRepeatX: boolean`
- `backgroundRepeatY: boolean`
- `backgroundOffsetX: number` — pixel offset along the horizontal axis
- `backgroundOffsetY: number` — pixel offset along the vertical axis
- `backgroundAlignX: "start" | "center" | "end"`
- `backgroundAlignY: "start" | "center" | "end"`

`backgroundOpacity` applies to image-backed backgrounds as an independent opacity control.

Final image-backed background alpha is:

- `resolvedImageAlpha = sourceAlpha * backgroundOpacity`

This revision standardizes:

- background source selection
- background repetition flags
- background offsets
- background alignment
- background opacity participation

This revision does not redefine the graphics-source object contracts, source loading lifecycle, or source-region model from the graphics specification.

## 7. Border Contract

## 7.1 Border Properties

The public border property family in this revision is:

- `borderColor`
- `borderOpacity`
- `borderWidth`
- `borderWidthTop`
- `borderWidthRight`
- `borderWidthBottom`
- `borderWidthLeft`
- `borderStyle`
- `borderJoin`
- `borderMiterLimit`
- `borderPattern`
- `borderDashLength`
- `borderGapLength`
- `borderDashOffset`

Borders are part of the styling contract for any root or named part whose owning component exposes border styling.

This revision also standardizes border placement.

The border is center-aligned on the styled bounds.

Implications:

- half of the resolved border width paints inward from the bounds edge
- half of the resolved border width paints outward from the bounds edge
- border painting does not alter layout measurement
- border painting does not alter hit-testing unless another component contract explicitly says otherwise

## 7.2 Border Width Model

Border widths resolve per-side in this revision.

`borderWidth` uses `SideQuad input` as defined in
[UI Foundation Specification](./ui-foundation-spec.md).

Per-side widths remain the canonical resolved form:

- `borderWidthTop`
- `borderWidthRight`
- `borderWidthBottom`
- `borderWidthLeft`

Per-side widths override the aggregate `borderWidth` input for their own side
when both are present at the same precedence layer.

Each border width:

- is numeric
- must be finite
- must not be negative

When all border widths resolve to zero, the border paints nothing.

## 7.3 Border Paint Model

`borderColor` defines the border paint color.

`borderOpacity` defines border opacity independently from color alpha so that non-color-backed border rendering and future border paint forms remain compatible with the same opacity contract.

Final border alpha is:

- `resolvedBorderAlpha = colorAlpha * borderOpacity`

## 7.4 Border Style And Line Behavior

The border line contract in this revision includes:

- `borderStyle`
- `borderJoin`
- `borderMiterLimit`
- `borderPattern`
- `borderDashLength`
- `borderGapLength`
- `borderDashOffset`

The purpose of these fields is:

- `borderStyle`: the stroke rendering quality family
- `borderJoin`: the corner join behavior
- `borderMiterLimit`: the miter threshold when the selected join behavior uses one
- `borderPattern`: the border segmentation family
- `borderDashLength`: the dash segment length in logical units when `borderPattern` is `"dashed"`
- `borderGapLength`: the gap segment length in logical units when `borderPattern` is `"dashed"`
- `borderDashOffset`: the dash phase offset in logical units when `borderPattern` is `"dashed"`

Accepted values in this revision:

- `borderStyle: "smooth" | "rough"`
- `borderJoin: "none" | "miter" | "bevel"`
- `borderMiterLimit: number | nil`
- `borderPattern: "solid" | "dashed"`
- `borderDashLength: number`
- `borderGapLength: number`
- `borderDashOffset: number`

`borderMiterLimit`:

- must be numeric
- must be finite
- must be greater than zero when present

`borderStyle` controls the stroke quality of the rendered line:

- `smooth`: antialiased line rendering
- `rough`: aliased line rendering

`borderJoin` controls the corner geometry where border segments meet:

- `miter`: segments meet with a sharp joined corner subject to `borderMiterLimit`
- `bevel`: the corner is flattened
- `none`: no additional join cap geometry is applied where segments meet

`borderStyle` and `borderPattern` are orthogonal. Any combination of the two is valid.

`borderPattern` controls the segmentation of the rendered border stroke:

- `solid`: the border paints as a continuous uninterrupted stroke
- `dashed`: the border paints as repeated dash-gap segments

Default values when not explicitly resolved:

- `borderPattern = "solid"`
- `borderDashLength = 8`
- `borderGapLength = 6`
- `borderDashOffset = 0`

`borderDashLength`:

- is numeric, expressed in logical units
- must be finite
- must be strictly greater than zero
- must not exceed 255

`borderGapLength`:

- is numeric, expressed in logical units
- must be finite
- must be greater than or equal to zero
- must not exceed 255

`borderDashOffset`:

- is numeric, expressed in logical units
- must be finite

The combined cycle (`borderDashLength + borderGapLength`) must not exceed 255 logical units. This ceiling aligns with the practical capacity of pattern-based rendering primitives and ensures consistent behavior across implementations.

When `borderPattern = "solid"`, `borderDashLength`, `borderGapLength`, and `borderDashOffset` are ignored.

When `borderPattern = "dashed"`:

- the dashed border is resolved from cumulative distance along the rendered border perimeter rather than restarting the dash phase at each side boundary
- `borderDashOffset` shifts dash phase along that same resolved perimeter
- `borderDashOffset = 0` preserves the default dash start
- positive `borderDashOffset` values advance the dash phase forward along the perimeter traversal used by this dashed-border contract
- negative `borderDashOffset` values shift the dash phase in the opposite direction
- a partial trailing dash is permitted when the perimeter length does not align with a whole cycle
- a side with a resolved border width of zero paints nothing for that side regardless of pattern settings
- `borderJoin` does not introduce join geometry across a dash gap
- rounded corners participate in the same cumulative-distance model as straight border segments
- rendered dash and gap lengths are the closest achievable approximation of the requested values; exact pixel-accurate fidelity is not guaranteed
- this contract is loose enough to give implementations space to consider trade-offs between compliance to a specific visual requirement and performance; when native or pattern-based host primitives can satisfy this contract, implementations should prefer those native facilities first, and custom dashed-border construction remains a fallback when native primitives cannot satisfy the contract
- when all resolved border widths are equal, implementations should preserve a continuous-path fast path rather than procedurally splitting geometry only to support rarer mixed-width cases
- differing resolved border widths remain valid and may require a segmented fallback path when the continuous-path fast path cannot satisfy the full border contract

`borderGapLength = 0` with `borderPattern = "dashed"` is valid and produces back-to-back dash segments with no visible gap. This is visually equivalent to `borderPattern = "solid"` and implementations may optimize this case accordingly.

Invalid border line configuration fails deterministically.

## 8. Corner Radius Contract

The public corner-radius property family in this revision is:

- `cornerRadius`
- `cornerRadiusTopLeft`
- `cornerRadiusTopRight`
- `cornerRadiusBottomRight`
- `cornerRadiusBottomLeft`

Corner radii:

- are numeric
- must be finite
- must not be negative

Corner radius affects:

- background geometry
- border geometry
- shadow and inset-shadow geometry where applicable
- clipping of background, gradient-backed background, and image-backed background paint to the resolved rounded geometry

`cornerRadius` uses `CornerQuad input` as defined in
[UI Foundation Specification](./ui-foundation-spec.md).

Per-corner values remain the canonical resolved form:

- `cornerRadiusTopLeft`
- `cornerRadiusTopRight`
- `cornerRadiusBottomRight`
- `cornerRadiusBottomLeft`

Per-corner values override the aggregate `cornerRadius` input for their own
corner when both are present at the same precedence layer.

When adjacent corner radii on one side exceed the available side length, the implementation must proportionally scale the affected radii down so the resolved corner geometry fits within the painted box.

For a center-aligned border, corner radius applies to the border stroke centerline.

Implications:

- the outer border arc expands outward by half of the local border width
- the inner border arc contracts inward by half of the local border width

## 9. Shadow Contract

## 9.1 Shadow Properties

The flat shadow property family in this revision is:

- `shadowColor`
- `shadowOpacity`
- `shadowOffsetX`
- `shadowOffsetY`
- `shadowBlur`
- `shadowInset`

Each styled root or named presentational part resolves at most one shadow in this revision.

Multiple simultaneous shadows are not part of this revision.

Shadow spread is not part of this revision.

## 9.2 Shadow Semantics

`shadowInset = false` defines an outer shadow.

`shadowInset = true` defines an inset shadow.

`shadowColor` is governed by the color-input rules in this document.

`shadowOpacity` is an independent opacity control.

Final shadow alpha is:

- `resolvedShadowAlpha = colorAlpha * shadowOpacity`

`shadowBlur`:

- is numeric
- must be finite
- must not be negative

Outer and inset shadows are both part of the first stable styling contract in this revision.

When corner radius is present:

- an outer shadow follows the resolved outer rounded silhouette
- an inset shadow follows the resolved inner rounded silhouette

Inset shadow paint is clipped to the node's interior bounds. The interior bounds are defined as the area inward from the border edge. Shadow blur falloff must not paint outside this region.

## 10. Skin, Tokens, And Styling

This document does not replace the skin or token systems.

Instead:

- styling properties are the authoritative visual-property definitions
- skins are a higher-level styling input source
- tokens remain a theme-system input source used by skins, defaults, or explicit styling resolution

Implications:

- a skin may provide values for any styling property recognized by this document
- a direct styling property overrides the corresponding skin value only for that property
- unresolved styling may continue to resolve through token-backed or library-backed defaults

The skin contract is defined in [UI Foundation Specification](./ui-foundation-spec.md). The token model is defined in [UI Foundation Specification](./ui-foundation-spec.md). This document defines only how styling properties participate as inputs to those systems and does not redefine the full token catalog or skin resolution mechanism.

## 10A. Relationship To Node-Level Opacity

This document defines styling-family opacity properties such as:

- `backgroundOpacity`
- `borderOpacity`
- `shadowOpacity`

Whole-node opacity remains the `Drawable.opacity` contract owned by [UI Foundation Specification](./ui-foundation-spec.md).

This document does not redefine node-level opacity. It defines only styling-family opacity inputs and how they combine with the alpha contribution of their corresponding styling source.

## 11. Graphics Interoperability

Image-backed backgrounds are styling concepts that depend on graphics concepts.

This document fully owns:

- the existence of image-backed backgrounds
- the styling properties that configure them
- how those properties participate in styling resolution

[UI Graphics Specification](./ui-graphics-spec.md) fully owns:

- `Texture`
- `Atlas`
- `Sprite`
- `Image`
- `NineSlice`
- source-region and image-presentation contracts

The accepted source types for `backgroundImage` in this revision are `Texture` and `Sprite`. `Image` is a retained display component and is not a valid `backgroundImage` source.

Neither specification partially defines the other.

## 11A. Paint Order

When the owning component exposes all corresponding styling families, the paint order in this revision is:

1. outer shadow
2. background
3. border
4. inset shadow
5. component content and descendants under the owning component's ordinary composition rules

## 12. Motion-Capable Styling Properties

Any styling property in this document that is numerically transitionable is motion-capable in this revision when targeted through a documented motion surface.

This includes, at minimum:

- `backgroundColor`
- `backgroundOpacity`
- gradient colors
- `borderColor`
- `borderOpacity`
- `borderWidth`
- `borderWidthTop`
- `borderWidthRight`
- `borderWidthBottom`
- `borderWidthLeft`
- `cornerRadius`
- `cornerRadiusTopLeft`
- `cornerRadiusTopRight`
- `cornerRadiusBottomRight`
- `cornerRadiusBottomLeft`
- `shadowColor`
- `shadowOpacity`
- `shadowOffsetX`
- `shadowOffsetY`
- `shadowBlur`

This document defines which styling properties are eligible for motion. [UI Motion Specification](./ui-motion-spec.md) remains authoritative for motion timing, interpolation, descriptors, surfaces, and adapter behavior.

## 13. Failure Semantics

Invalid styling input is a hard failure unless this document explicitly defines a supported conversion or coercion path for that input family.

Hard-failure cases include:

- unsupported enum value
- unsupported named color
- invalid hex color syntax
- invalid gradient structure
- invalid graphics-backed source type for an image-backed background
- opacity outside `[0, 1]`
- numeric color component exceeding `255` in a detected `[0, 255]` range input
- non-integer component value in a detected `[0, 255]` range input
- negative width, blur, or radius where not permitted
- invalid border line configuration
- `borderPattern` outside the accepted enum set
- non-finite `borderDashLength`, `borderGapLength`, or `borderDashOffset`
- `borderDashLength <= 0`
- `borderDashLength > 255`
- `borderGapLength < 0`
- `borderGapLength > 255`
- `borderDashLength + borderGapLength > 255`

Supported conversion cases include:

- accepted non-RGBA color forms that resolve into RGBA
- accepted shorthand or equivalent input forms explicitly documented by the implementation under this contract

The library must not silently reinterpret an invalid input as a nearby valid style unless this document explicitly permits that conversion path.

## 14. Stability

The styling-property families, value categories, precedence order, and ownership boundaries defined by this document are `Stable` as of `0.1.0`.

This revision stabilizes:

- color-backed backgrounds
- gradient-backed backgrounds
- image-backed backgrounds
- border styling
- per-corner radius styling
- outer shadows
- inset shadows
- field-by-field precedence between direct properties, skin values, and token-backed or library-backed fallbacks

This revision does not imply any undocumented shorthand, alias, convenience schema, or grouped style object beyond the flat property families defined here.
