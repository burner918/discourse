import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export const LIGHT = "light";
export const DARK = "dark";

function isColorOverriden(color, darkModeActive) {
  if (darkModeActive) {
    return color.defaultDarkValue && color.defaultDarkValue !== color.darkValue;
  } else {
    return (
      color.defaultLightValue && color.defaultLightValue !== color.lightValue
    );
  }
}

class Color {
  @tracked lightValue;
  @tracked darkValue;

  constructor({
    name,
    lightValue,
    darkValue,
    description,
    translatedName,
    defaultLightValue,
    defaultDarkValue,
  }) {
    this.name = name;
    this.lightValue = lightValue;
    this.darkValue = darkValue;
    this.displayName = translatedName;
    this.description = description;
    this.defaultLightValue = defaultLightValue;
    this.defaultDarkValue = defaultDarkValue;
  }
}

const NavTab = <template>
  <li>
    <a
      class={{concatClass "" (if @active "active")}}
      tabindex="0"
      {{on "click" @action}}
      {{on "keydown" @action}}
      ...attributes
    >
      {{icon @icon}}
      <span>{{@label}}</span>
    </a>
  </li>
</template>;

const Picker = class extends Component {
  @service toasts;

  @action
  onInput(event) {
    const color = event.target.value.replace("#", "");
    if (this.args.showDark) {
      this.args.color.darkValue = color;
    } else {
      this.args.color.lightValue = color;
    }
  }

  @action
  onChange(event) {
    const color = event.target.value.replace("#", "");
    if (this.args.showDark) {
      this.args.onDarkChange(color);
      this.args.color.darkValue = color;
    } else {
      this.args.onLightChange(color);
      this.args.color.lightValue = color;
    }
  }

  @action
  onTextChange(event) {
    const color = event.target.value;
    if (this.args.showDark) {
      this.args.onDarkChange(color);
      this.args.color.darkValue = color;
    } else {
      this.args.onLightChange(color);
      this.args.color.lightValue = color;
    }
  }

  @action
  onTextKeypress(event) {
    const color = event.target.value + event.key;

    if (color && !color.match(/^[0-9A-Fa-f]+$/)) {
      event.preventDefault();
      this.toasts.error({
        data: {
          message: i18n(
            "admin.config_areas.color_palettes.illegal_character_in_color"
          ),
        },
      });
    }
  }

  get displayedColor() {
    let color;
    if (this.args.showDark) {
      color = this.args.color.darkValue ?? this.args.color.lightValue;
    } else {
      color = this.args.color.lightValue ?? this.args.color.darkValue;
    }
    return this.ensureSixDigitsHex(color);
  }

  get activeValue() {
    let color;
    if (this.args.showDark) {
      color = this.args.color.darkValue ?? this.args.color.lightValue;
    } else {
      color = this.args.color.lightValue ?? this.args.color.darkValue;
    }

    if (color) {
      return `#${this.ensureSixDigitsHex(color)}`;
    }
  }

  ensureSixDigitsHex(hex) {
    if (hex.length === 3) {
      return hex
        .split("")
        .map((digit) => `${digit}${digit}`)
        .join("");
    }
    return hex;
  }

  <template>
    <input
      class="color-palette-editor__input"
      type="color"
      value={{this.activeValue}}
      {{on "input" this.onInput}}
      {{on "change" this.onChange}}
    />
    {{icon "hashtag"}}
    <input
      class="color-palette-editor__text-input"
      type="text"
      maxlength="6"
      value={{this.displayedColor}}
      {{on "keypress" this.onTextKeypress}}
      {{on "change" this.onTextChange}}
    />
  </template>
};

export default class ColorPaletteEditor extends Component {
  @tracked selectedMode;

  get currentMode() {
    return this.selectedMode ?? this.args.initialMode ?? LIGHT;
  }

  get lightModeActive() {
    return this.currentMode === LIGHT;
  }

  get darkModeActive() {
    return this.currentMode === DARK;
  }

  get colors() {
    return this.args.colors.map((color) => {
      return new Color({
        name: color.name,
        lightValue: color.hex,
        darkValue: color.dark_hex,
        description: color.description,
        translatedName: color.translatedName,
        defaultLightValue: color.default_hex,
        defaultDarkValue: color.default_dark_hex,
      });
    });
  }

  @action
  changeMode(newMode, event) {
    if (
      event.type === "click" ||
      (event.type === "keydown" && event.keyCode === 13)
    ) {
      if (this.args.onTabSwitch) {
        this.args.onTabSwitch(newMode);
      } else {
        this.selectedMode = newMode;
      }
    }
  }

  @action
  revert(color) {
    if (this.darkModeActive) {
      this.args.onDarkColorChange(color.name, color.defaultDarkValue);
      color.darkValue = color.defaultDarkValue;
    } else {
      this.args.onLightColorChange(color.name, color.defaultLightValue);
      color.lightValue = color.defaultLightValue;
    }
  }

  <template>
    <div class="color-palette-editor">
      <div class="nav-pills color-palette-editor__nav-pills">
        <NavTab
          @active={{this.lightModeActive}}
          @action={{fn this.changeMode LIGHT}}
          @icon="sun"
          @label={{i18n "admin.customize.colors.editor.light"}}
          class="light-tab"
        />
        <NavTab
          @active={{this.darkModeActive}}
          @action={{fn this.changeMode DARK}}
          @icon="moon"
          @label={{i18n "admin.customize.colors.editor.dark"}}
          class="dark-tab"
        />
      </div>
      <div class="color-palette-editor__colors-list">
        {{#each this.colors as |color|}}
          <div
            data-color-name={{color.name}}
            class="color-palette-editor__colors-item"
          >
            <div class="color-palette-editor__color-info">
              <div class="color-palette-editor__color-description">
                {{#if color.description}}
                  {{color.description}}
                {{else}}
                  {{color.displayName}}
                {{/if}}
              </div>
              {{#if color.description}}
                <div class="color-palette-editor__color-name">
                  {{color.displayName}}
                </div>
              {{/if}}
            </div>
            <div class="color-palette-editor__color-controls">
              <div class="color-palette-editor__picker">
                <Picker
                  @color={{color}}
                  @showDark={{this.darkModeActive}}
                  @onLightChange={{fn @onLightColorChange color.name}}
                  @onDarkChange={{fn @onDarkColorChange color.name}}
                />
              </div>
              <DButton
                class={{concatClass
                  "btn-flat"
                  "color-palette-editor__revert"
                  (unless
                    (isColorOverriden color this.darkModeActive) "--hidden"
                  )
                }}
                @icon="arrow-rotate-left"
                @action={{fn this.revert color}}
              />
            </div>
          </div>
        {{/each}}
      </div>
    </div>
  </template>
}
