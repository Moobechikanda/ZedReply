<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  name: '',
  description: '',
  productName: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
    contactAttributes: false,
  },
};

// Keep these keys aligned with Captain::Assistant::BUSINESS_PROFILE_FIELDS.
const businessProfileFields = [
  {
    key: 'company_description',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.COMPANY_DESCRIPTION.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.COMPANY_DESCRIPTION.PLACEHOLDER'
      ),
  },
  {
    key: 'industry',
    label: () => t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.INDUSTRY.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.INDUSTRY.PLACEHOLDER'),
  },
  {
    key: 'mission',
    label: () => t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.MISSION.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.MISSION.PLACEHOLDER'),
  },
  {
    key: 'vision',
    label: () => t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.VISION.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.VISION.PLACEHOLDER'),
  },
  {
    key: 'values',
    label: () => t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.VALUES.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.VALUES.PLACEHOLDER'),
  },
  {
    key: 'contact_details',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CONTACT_DETAILS.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CONTACT_DETAILS.PLACEHOLDER'),
  },
  {
    key: 'offerings_and_pricing',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.OFFERINGS_AND_PRICING.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.OFFERINGS_AND_PRICING.PLACEHOLDER'
      ),
  },
  {
    key: 'business_hours',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.BUSINESS_HOURS.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.BUSINESS_HOURS.PLACEHOLDER'),
  },
  {
    key: 'locations_and_service_area',
    label: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.LOCATIONS_AND_SERVICE_AREA.LABEL'
      ),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.LOCATIONS_AND_SERVICE_AREA.PLACEHOLDER'
      ),
  },
  {
    key: 'policies',
    label: () => t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.POLICIES.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.POLICIES.PLACEHOLDER'),
  },
  {
    key: 'faqs_and_eligibility',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.FAQS_AND_ELIGIBILITY.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.FAQS_AND_ELIGIBILITY.PLACEHOLDER'
      ),
  },
  {
    key: 'communication_style',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.COMMUNICATION_STYLE.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.COMMUNICATION_STYLE.PLACEHOLDER'
      ),
  },
  {
    key: 'supported_languages',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.SUPPORTED_LANGUAGES.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.SUPPORTED_LANGUAGES.PLACEHOLDER'
      ),
  },
  {
    key: 'response_limits',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.RESPONSE_LIMITS.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.RESPONSE_LIMITS.PLACEHOLDER'),
  },
  {
    key: 'human_handoff',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.HUMAN_HANDOFF.LABEL'),
    placeholder: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.HUMAN_HANDOFF.PLACEHOLDER'),
  },
  {
    key: 'connected_systems',
    label: () =>
      t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CONNECTED_SYSTEMS.LABEL'),
    placeholder: () =>
      t(
        'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CONNECTED_SYSTEMS.PLACEHOLDER'
      ),
  },
];

const emptyBusinessProfile = () => ({
  ...Object.fromEntries(businessProfileFields.map(({ key }) => [key, ''])),
  catalog_items: [],
});

const businessProfileInputs = computed(() =>
  businessProfileFields.map(({ key, label, placeholder }) => ({
    key,
    label: label(),
    placeholder: placeholder(),
  }))
);

const state = reactive({
  ...initialState,
  businessProfile: emptyBusinessProfile(),
});

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
}));

const addCatalogItem = () => {
  state.businessProfile.catalog_items.push({
    kind: 'product',
    name: '',
    category: '',
    sku: '',
    price: '',
    currency: '',
    availability: '',
    options: '',
    description: '',
    faq: '',
    image_url: '',
    archived: false,
  });
};

const toggleCatalogItemArchive = item => {
  item.archived = !item.archived;
};

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.businessProfile = {
    ...emptyBusinessProfile(),
    ...config.business_profile,
  };
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
    contactAttributes: config.feature_contact_attributes || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.productName.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      product_name: state.productName,
      business_profile: { ...state.businessProfile },
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
      feature_contact_attributes: state.features.contactAttributes,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Input
      v-model="state.productName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      :message="formErrors.productName"
      :message-type="formErrors.productName ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :max-length="500"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <section class="flex flex-col gap-4 border-t border-n-weak pt-5">
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.TITLE') }}
        </h3>
        <p class="mb-0 text-sm text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex flex-col gap-4">
        <div v-for="field in businessProfileInputs" :key="field.key">
          <TextArea
            :id="`business-profile-${field.key}`"
            v-model="state.businessProfile[field.key]"
            :label="field.label"
            :placeholder="field.placeholder"
            auto-height
            min-height="6rem"
            max-height="18rem"
          />
        </div>
      </div>
    </section>

    <section class="flex flex-col gap-4 border-t border-n-weak pt-5">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex flex-col gap-1">
          <h3 class="text-base font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.TITLE') }}
          </h3>
          <p class="mb-0 text-sm text-n-slate-11">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.DESCRIPTION')
            }}
          </p>
        </div>
        <Button
          :label="t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.ADD')"
          @click="addCatalogItem"
        />
      </div>

      <p
        v-if="!state.businessProfile.catalog_items.length"
        class="mb-0 text-sm text-n-slate-11"
      >
        {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.EMPTY') }}
      </p>

      <article
        v-for="(item, index) in state.businessProfile.catalog_items"
        :key="index"
        class="flex flex-col gap-4 rounded-lg border border-n-weak p-4"
        :class="{ 'opacity-60': item.archived }"
      >
        <div class="flex flex-wrap items-center justify-between gap-3">
          <h4 class="mb-0 text-sm font-medium text-n-slate-12">
            {{
              item.name ||
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.ITEM')
            }}
            <span v-if="item.archived" class="ms-2 text-n-slate-10">
              {{
                t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.ARCHIVED')
              }}
            </span>
          </h4>
          <Button
            :label="
              item.archived
                ? t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.RESTORE')
                : t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.ARCHIVE')
            "
            @click="toggleCatalogItemArchive(item)"
          />
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label
            class="flex flex-col gap-1 text-sm font-medium text-n-slate-12"
          >
            {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.KIND') }}
            <select
              v-model="item.kind"
              class="h-10 rounded-lg border border-n-weak bg-n-background px-3 text-sm font-normal"
            >
              <option value="product">
                {{
                  t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.PRODUCT')
                }}
              </option>
              <option value="service">
                {{
                  t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.SERVICE')
                }}
              </option>
            </select>
          </label>
          <Input
            v-model="item.name"
            :label="t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.NAME')"
          />
          <Input
            v-model="item.category"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.CATEGORY')
            "
          />
          <Input
            v-model="item.sku"
            :label="t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.SKU')"
          />
          <Input
            v-model="item.price"
            :label="t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.PRICE')"
          />
          <Input
            v-model="item.currency"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.CURRENCY')
            "
          />
          <Input
            v-model="item.availability"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.AVAILABILITY')
            "
          />
          <TextArea
            v-model="item.options"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.OPTIONS')
            "
            :placeholder="
              t(
                'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.OPTIONS_PLACEHOLDER'
              )
            "
            auto-height
            min-height="5rem"
            max-height="12rem"
          />
          <TextArea
            v-model="item.description"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.DESCRIPTION')
            "
            auto-height
            min-height="5rem"
            max-height="12rem"
          />
          <Input
            v-model="item.image_url"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.IMAGE_URL')
            "
          />
          <TextArea
            v-model="item.faq"
            :label="t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.FAQ')"
            :placeholder="
              t(
                'CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.CATALOG.FAQ_PLACEHOLDER'
              )
            "
            auto-height
            min-height="5rem"
            max-height="12rem"
          />
        </div>
      </article>
    </section>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </label>
      <div class="flex flex-col gap-2">
        <label class="flex items-center gap-2">
          <input v-model="state.features.conversationFaqs" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.memories" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.citations" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.contactAttributes" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONTACT_ATTRIBUTES') }}
        </label>
      </div>
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleBasicInfoUpdate"
      />
    </div>
  </div>
</template>
